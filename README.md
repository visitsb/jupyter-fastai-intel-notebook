# Jupyter notebook with Fastai (on top of Intel® oneAPI PyTorch) kernel
Based on [fastai](https://github.com/fastai/fastai) on top of [Intel® AI Analytics Toolkit](https://github.com/intel/oneapi-containers#intel-ai-analytics-toolkit). 

Also bundles [Intel® software for general purpose GPU capabilities](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-bionic.html) to allow exposing Intel GPUs to PyTorch, however since [Intel® PyTorch](https://intel.github.io/stacks/dlrs/pytorch/README.html) is pre-optimized for CPU so it might not be relevant.

Please switch or use Jupyter kernel named `Fastai (Intel® oneAPI)`. This Jupyter kernel is available to run your notebook using Fastai kernel.

A simple example using Fastai-

```
from fastai.vision.all import *
path = untar_data(URLs.PETS)/'images'
def is_cat(x): return x[0].isupper()
dls = ImageDataLoaders.from_name_func(
 path, get_image_files(path), valid_pct=0.2, seed=42,
 label_func=is_cat, item_tfms=Resize(224))
 learn = cnn_learner(dls, resnet34, metrics=error_rate)
learn.fine_tune(1)
```

~~Precludes [Deep Learning Reference Stack with Tensorflow and Intel® oneAPI Deep Neural Network Library (oneDNN)](https://intel.github.io/stacks/dlrs/tensorflow/README.html) and [Intel® Distribution of Modin](https://anaconda.org/intel/intel-aikit-modin)~~

# Docker
When running docker container ensure you provide shared memory `shm-size` for [PyTorch to run it's data workers](https://github.com/pytorch/pytorch/issues/5040) successfully.

```
/usr/bin/docker run --tty \
                    --interactive --rm \
                    --privileged --device=/dev/dri \
                    --shm-size=2G \
                    --volume /tmp:/home/work:rw \
                    --volume /tmp/fastai:/home/jovyan/.fastai:rw \
                    --volume /tmp/fastbook:/home/jovyan/fastbook:rw \
                    --name jupyter-fastai-intel-notebook \
visitsb/jupyter-fastai-intel-notebook:latest
```

**Note**: `--privileged --device=/dev/dri` allows an alternative means to [expose your local GPUs](https://github.com/docker/cli/pull/1714) to the docker image, but I haven't verified if Intel based GPUs are successfully utilized by Intel® PyTorch.

Below volumes to mount externally
- `home/jovyan/.fastai` - Contains sample training data, models for Fastai
- `home/jovyan/fastbook` - Contains local copy of [Fastbook](https://github.com/fastai/fastbooks). Please do consider purchasing their excellent [book](https://www.amazon.com/Deep-Learning-Coders-fastai-PyTorch/dp/1492045527).

**Tip**: You might want to first copy out the contents from these volumes locally before mounting them for `rw` use (see above example run command to temporarily mount `/tmp` on `home/work` to copy out data)