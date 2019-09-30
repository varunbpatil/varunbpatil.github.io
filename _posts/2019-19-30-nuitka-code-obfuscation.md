---
layout: post
title: "Python code obfuscation using Nuitka"
---

Recently, the company I work for - <b>Noodle.ai</b> - had to make a on-premise deployment for one of its customers.

I was asked to find a way to obfuscate Python code so that our customer couldn't simply just open up the Python files and look at the code inside.

My solution was to use a Python compiler called [Nuitka](https://nuitka.net/pages/overview.html).

Below is a small Python script which will go through all the specified directories and compile the `.py` files into `.so` files.

These `.so` files can be imported into any Python file just like you would any other normal `.py` file.

<b>NOTE:</b>
* You should not be compiling the `__init__.py` files which are used by Python to denote packages.
* You should also not compile the python file that contains the main function or starting point of your application since you cannot call `.so` files using the Python interpreter.

```python
#!/usr/bin/env python
#
# Code obfuscation using nuitka
# Convert python code to shared object.
#
import os
import pprint


# Project directories to run nuitka on.
# Edit this to include the directories you want.
PROJECT_DIRS = [
    'src/data',
    'src/drivers',
    'src/features',
    'src/models',
    'src/scripts'
]

EXCLUDE_FILES = [
    '__init__.py'
]


def main():
    """
    Go through each python file in the given project directories and
    convert python code to shared object using nuitka.
    Remove the original .py file as well.
    """
    py_files_processed = []

    for nuitka_dir in PROJECT_DIRS:
        for root, _, files in os.walk(nuitka_dir):
            for file in files:
                if file.endswith('.py'):
                    if file in EXCLUDE_FILES:
                        continue

                    file_path = os.path.join(root, file)

                    print(f'Processing file: {file_path}')
                    py_files_processed.append(file_path)

                    # Remove doc-strings from shared object by passing -OO
                    # flag.
                    cmd = ('python -m nuitka --module --python-flag=-OO '
                           '--remove-output --lto --output-dir={} {}')
                    os.system(cmd.format(root, file_path))

                    # Remove the original .py file.
                    os.remove(file_path)

    print('Processed the following py files:')
    pprint.pprint(py_files_processed)


if __name__ == '__main__':
    main()
```

At <b>Noodle.ai</b> we deploy our apps as dockerized containers.

So, in the [next post]({% post_url 2019-09-30-multistage-docker-build %}), we'll look at how to write a single <b>Dockerfile</b> that can be used to build a Docker image with both unobfuscated and obfuscated code with just a single build argument.
