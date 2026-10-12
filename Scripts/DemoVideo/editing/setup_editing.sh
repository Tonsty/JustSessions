#!/bin/zsh
# setup_editing.sh: the edit's Python environment in $DEMO_WORK/.venv, and the Kokoro narration model
# (Apache-2.0 weights, about 340 MB) in $DEMO_WORK/models/kokoro, checked against its published checksums.
set -e
source ${0:A:h:h}/settings.sh
mkdir -p $DEMO_WORK
uv venv -q --allow-existing --python 3.12 $DEMO_WORK/.venv
uv pip install -q --python $DEMO_WORK/.venv/bin/python -r ${0:A:h}/requirements.txt

models=$DEMO_WORK/models/kokoro
release=https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0
mkdir -p $models
for file checksum in \
  kokoro-v1.0.onnx beb0d1848dee9a49da392cc3df26958d46cfa35d321edf434f52949153f0df3a \
  voices-v1.0.bin bca610b8308e8d99f32e6fe4197e7ec01679264efed0cac9140fe9c29f1fbf7d; do
  if ! echo "$checksum  $models/$file" | shasum -a 256 -c -s 2>/dev/null; then
    curl -fL --progress-bar -o $models/$file $release/$file
    echo "$checksum  $models/$file" | shasum -a 256 -c -s || { echo "$file: checksum mismatch"; rm -f $models/$file; exit 1; }
  fi
done
echo "editing environment ready in $DEMO_WORK"
