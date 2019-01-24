PLATFORMS = ['IBM', 'GCP', 'Azure', 'AWS']

def main(platform):
    if platform.upper() == 'GCP':
        import gcp_provisioner as provisioner
    else:
        raise Exception("Cloud Platform not Supported")

    provisioner.execute()


if __name__ == '__main__':
    from argeparse import ArgumentParser
    arg_parser = ArgumentParser()
    arg_parser.add_argument('-P', '--platform', required=True)

    main(**arg_parser.parser_args().__dict__)
