check_cmd() {
  command -v "$1" > /dev/null 2>&1
  return $?
}

say() {
    echo "$1"
}

err() {
  local red;red=$(tput setaf 1 2>/dev/null || echo '')
  local reset;reset=$(tput sgr0 2>/dev/null || echo '')
  say "${red}ERROR${reset}: $1" >&2
  exit 1
}

get_architecture() {
  local _ostype;_ostype="$(uname -s | tr '[:upper:]' '[:lower:]')"
  local _arch;_arch="$(uname -m)"
  local _arm=("arm armhf aarch64 aarch64_be armv6l armv7l armv8l arm64e") # arm64
  local _amd=("x86 x86pc i386 i686 i686-64 x64 x86_64 x86_64h athlon")    # amd64

  if [[ "${_arm[*]}" =~ ${_arch} ]]; then
    _arch="arm64"
  elif [[ "${_amd[*]}" =~ ${_arch} ]]; then
    _arch="amd64"
  elif [[ "${_arch}" != "ppc64le" ]]; then
    echo -e "ERROR: unsupported architecture \"${_arch}\"" >&2
    exit 2
  fi

  RETVAL="${_ostype}-${_arch}"
}

need_cmd() {
  if ! check_cmd "$1"; then
    err "need '$1' (command not found)"
  fi
}

# This wraps curl or wget.
# Try curl first, if not installed, use wget instead.
downloader() {
  if check_cmd curl; then
    _dld=curl
  elif check_cmd wget; then
    _dld=wget
  else
    _dld='curl or wget' # to be used in error message of need_cmd
  fi

  if [ "$1" = --check ]; then
    need_cmd "$_dld"
  elif [ "$_dld" = curl ]; then
    curl -sSfL "$1" -o "$2"
  elif [ "$_dld" = wget ]; then
    wget "$1" -O "$2"
  else
    err "Unknown downloader"
  fi
}

get_version() {
  local _plugin=${BUILDKITE_PLUGINS:-""}
  local _version;_version=$(echo "$_plugin" | sed -e 's/.*ecs-task-runner//' -e 's/\".*//')
  RETVAL="$_version"
}

foundFiles=()
fileDigests=""

findFilesByExtension() {
  local directory="$1"
  local extension="$2"

  # Loop through all files and directories in the current directory
  for item in "$directory"/*; do
    if [ -f "$item" ] && [ "${item##*.}" = "$extension" ]; then
    echo "File with extension '.$extension' found: $item"
    foundFiles+=("$item")  # Store the file path in the array
    elif [ -d "$item" ]; then
      # Recursively search in subdirectories
      findFilesByExtension "$item" "$extension"
    fi
  done
}

# Function to calculate MD5 digest for a file
calculateMD5() {
  local file="$1"
  md5sum "$file" | awk '{print $1}'  # Extract the MD5 digest
}

download_binary_and_run() {
  get_architecture || return 1
  findFilesByExtension "." "avsc"

  local schema_names_for_task=""
  # for ((i = 0; i < ${#schema_names[@]}; i++)); do
    # if [ "$i" -eq 0 ]; then
    #   schema_names_for_task="${schema_names[i]}"
    # else
    #   schema_names_for_task+=",${schema_names[i]}"
    # fi
    
  # done

  for ((i = 0; i < ${#foundFiles[@]}; i++)); do
    md5=$(calculateMD5 "$foundFiles[i]")
    filename=$(basename "$foundFiles[i]")
    filenameWithoutExtension="${filename%.*}"
    if [ "$i" -eq 0 ]; then
      fileDigests+="$filenameWithoutExtension: $md5"
    else
      fileDigests+=",$filenameWithoutExtension: $md5"
    fi
  done

  # Print the file MD5 digests for ".avsc" files
  echo "File MD5 Digests for all found '.avsc' files:"
  echo "fileDigests: ${fileDigests}"

  local _arch="$RETVAL"
  local _executable="ecs-run-task"
  local _repo="https://github.com/buildkite/ecs-run-task"

  # get_version || return 1
  # local _version="$RETVAL"

  # if [ -z "${_version}" ]; then
  # else
  #   _url=${_repo}/releases/download/${_version:1}/${_executable}_${_arch}
  # fi
  _url=${_repo}/releases/latest/download/${_executable}-${_arch}

  if ! downloader "$_url" "$_executable"; then
    say "failed to download $_url"
    exit 1
  fi

  chmod +x ${_executable}

  # ./${_executable}
}
