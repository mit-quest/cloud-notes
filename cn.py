#!/usr/bin/env python3

import subprocess
import typing

NoneStr = typing.TypeVar('NoneStr', str, None)

from providers import CloudProvider

def setup_args(parser):
    app_group = parser.add_mutually_exclusive_group(required=True)

    app_group.add_argument(
            '-a',
            '--application',
            dest='app_source',
            type=str)

    app_group.add_argument(
            '-w',
            '--workspace',
            dest='app_source',
            type=str,
            help='The application to build into a deployable cloud resource.')

    parser.add_argument(
            '-d',
            '--datasource',
            dest='data_source',
            type=str,
            help='The data source used by  cloud resource.')

    parser.add_argument(
            '-n',
            '--name',
            metavar='APPLICATION_NAME',
            dest='app_name',
            type=str,
            help='The name of the application resource.')

    parser.add_argument(
            '-p',
            '--provider',
            required=True,
            type=CloudProvider,
            help='The name of a cloud resource provider used to deploy resources.')

    parser.add_argument(
            '-t',
            '--template',
            help="""A Dockerfile used to modify the default workspace environment.
                    This is a post-build step which will be applied after dependency management.
                    An example use case for templates is GPU support for the application within
                    workspace. A template will acquire the docker build context of the template's
                    location. A GPU template is provided for CUDA development support.""")

    return parser

def validate(app_source: str, data_source: str):
    pass

def build(app_source: str, app_name: str):
    pass

def deploy():
    pass

def main(
        app_name: NoneStr,
        app_source: str,
        data_source: str,
        provider: CloudProvider,
        template: NoneStr,
        *args,
        **kwargs) -> None:

    process = [
            './cn',
            '-p', provider.value,
            '-w', app_source,
            '-d', data_source
    ]

    if app_name:
        process.extend(['-n', app_name])

    if template:
        process.extend(['-t', template])

    print(process)

    subprocess.Popen(process)

if __name__  == '__main__':
    import sys
    import argparse

    parser = setup_args(argparse.ArgumentParser(sys.argv[0]))
    main(**parser.parse_args().__dict__)
