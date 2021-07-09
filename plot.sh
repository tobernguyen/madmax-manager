#!/usr/bin/env bash

set -e

PLOT_SIZE_IN_KBYTES=108900000 # Maximum size for a k32 plot in kilobytes

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
dir_resolve()
{
  cd "$1" 2>/dev/null || return $?  # cd to desired directory; if fail, quell any error messages but return exit status
  pwd -P # output full, link-resolved path
}

if ! chia_plot --help &> /dev/null; then
  echo "Couldn't find chia_plot in your PATH. Please make sure the MadMax chia_plot binary is installed and you can run \"chia_plot\" in your shell."
  exit 1
fi

# Load configurations
if [[ ! -f config.ini ]]; then
  echo "Couldn't find config.ini. Please create config.ini from config.ini.example and set appropriate values."
fi
# shellcheck source=config.ini.example
source "$SCRIPT_DIR"/config.ini

# Make sure log_dir, tmp_1_dir, and tmp_2_dir exist
dir_types=(log_dir tmp_1_dir tmp_2_dir)
for dir_type in "${dir_types[@]}"; do
  if [[ -z "${!dir_type}" ]]; then
    echo "Missing value for $dir_type. Please set it in config.ini file."
    exit 1
  fi
  if [[ ! "${!dir_type}" == */ ]]; then
    echo "Value of $dir_type must end with / (slash)."
    exit 1
  fi
  mkdir -p "${!dir_type}"
done

# Check destinations
num_of_dest_dirs=0
IFS=$','
for dest_dir in $destination_dirs; do
  if [[ ! "${dest_dir}" == */ ]]; then
    echo "Invalid destination dir \"$dest_dir\". Destination dir must end with / (slash)."
    exit 1
  fi
  mkdir -p "$dest_dir"
  ((num_of_dest_dirs+=1))
done
if [[ "$num_of_dest_dirs" -lt "1" ]]; then
  echo "Must have at least one destination dir. Please set it in config.ini file."
  exit 1
fi

# Check required configs
required_keys=(pool_public_key farmer_public_key)
for key in "${required_keys[@]}"; do
  if [[ -z "${!key}" ]]; then
    echo "Missing value for $key. Please set it in config.ini file."
    exit 1
  fi
done

# Start the plotter
for dest_dir in $destination_dirs; do
  done_plotting=false
  while [ "$done_plotting" != "true" ]; do
    args=()

    current_dir_number_of_plots=0
    if [[ "$number_of_plots" -lt "1" ]]; then
      echo "Number of plot is set to 0. The manager will try to calculate and fill up all destination dirs."
      dest_dir_available_kbytes=$(df -k "$dest_dir" | awk '$3 ~ /[0-9]+/ { print $4 }')
      current_dir_number_of_plots=$((dest_dir_available_kbytes / PLOT_SIZE_IN_KBYTES))
      echo "Number of plots for $dest_dir: $current_dir_number_of_plots"
    else
      current_dir_number_of_plots=$number_of_plots
    fi
    if [[ "$current_dir_number_of_plots" -lt "1" ]]; then
      echo "Skip destination dir $dest_dir because it couldn't fit any new plot."
      break
    fi
    args+=(-n "$current_dir_number_of_plots")
    args+=(-f "$farmer_public_key")
    args+=(-t "$tmp_1_dir")
    args+=(-2 "$tmp_2_dir")
    args+=(-d "$dest_dir")

    [[ -n "${pool_public_key:-}" ]] && args+=(-p "$pool_public_key")
    [[ -n "${pool_contract_address:-}" ]] && args+=(-c "$pool_contract_address")
    [[ -n "${number_of_threads:-}" ]] && args+=(-r "$number_of_threads")
    [[ -n "${number_of_buckets:-}" ]] && args+=(-u "$number_of_buckets")

    plot_job_id=$(date +"%Y-%m-%d_%H-%M-%S_%Z")
    # shellcheck disable=SC2154
    log_file_path=$(dir_resolve "$log_dir")/${plot_job_id}.log
    # Create screen configuration file
    printf "deflog on\nlog on\nlogfile %s\nlogfile flush 5" "$log_file_path" > /tmp/madmax-manager-screen.conf
    if [[ "$auto_clean_tmp_dirs_on_start" == "true" ]]; then
      echo "Cleaning up tmp dirs..."
      rm -rf "${tmp_1_dir}"*
      rm -rf "${tmp_2_dir}"*
    fi
    plotter_command=$(IFS=' ';printf 'chia_plot %s' "${args[*]}")
    echo "Starting plotter: ${plotter_command}"
    # shellcheck disable=SC2154
    screen -c /tmp/madmax-manager-screen.conf -dmLS "plot_${plot_job_id}" bash -c "${plotter_command} && echo \"=====JOB EXITED SUCCESS=====\" || echo \"=====JOB EXITED FAILURE=====\""
    
    # Sleep 6 seconds so the logfile is flushed 
    sleep 6
    while IFS= read -r LOGLINE || [[ -n "$LOGLINE" ]]; do
      printf '%s\n' "$LOGLINE"
      if [[ "${LOGLINE}" =~ ^"=====JOB EXITED SUCCESS=====" ]]; then
        echo "Finished plotting into $dest_dir successfully."
        done_plotting=true
        break
      fi
      if [[ "${LOGLINE}" =~ ^"=====JOB EXITED FAILURE=====" ]]; then
        echo "Plotting crash detected."
        # shellcheck disable=SC2154
        if [[ "$auto_restart_on_crash" == "false" ]];then
          echo "Auto restart on crash set to false. Won't restart the plotter."
          done_plotting=true
        else
          echo "Auto restart on crash set to true. Restarting the plotter..."
        fi
        break
      fi
    done < <(tail -f "$log_file_path")
  done
done
