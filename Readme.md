### Koreader Tuya Plugin

Control your tuya bulbs in koreader.

Uses TinyTuya

Licenced AGPL

#### python install

To install TinyTuya on your Kindle, install NiLuJe's python3 package.

Install the correct kindle cross toolchain and load it into your `$PATH`
Extract the python3 package locally on your computer in the examle below it is in `./python3`

Your python version must be the same as the one in NiLuJe's package

Then:

```bash
python -m crossenv ./python3/bin/python3.9 cross
source ./cross/bin/activate
python -m pip install tinytuya
```

Youn can then copy the `site-packages` folder to your kindle's python install.
