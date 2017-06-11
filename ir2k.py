import sys
import time
import struct
import ConfigParser

from os import path, system
from argparse import ArgumentParser

SOCKET = "/dev/input/event0"

FORMAT = 'llHHI'
EVENT_SIZE = struct.calcsize(FORMAT)

CONFIG_FILE = 'keys.cfg'
PATH_CONFIG = '{0}{1}'.format('./', CONFIG_FILE)

Config = ConfigParser.ConfigParser()
Config.add_section('Keys')
Config.add_section('Commands')

last_time = time.time()


def fetch_config_keys(path_cfg_file):
    if path.exists(path_cfg_file):
        Config.read(path_cfg_file)
    else:
        sys.exit()


def kill_all_processes():
    system('killall -q madplay wget &> /dev/null')


def timeit(method):
    def timed(*args):
        global last_time
        now = time.time()
        if (now - last_time) > 0.5:
            method(*args)
            last_time = time.time()
        return

    return timed


@timeit
def record_keys(value):
    name_key = raw_input('Write name key {}, Example: KEY_POWER:'.format(value))
    Config.set('Keys', str(value), name_key)


@timeit
def exec_command(value):
    try:
        command = ''
        if Config.has_option('Keys', str(value)):
            command = Config.get('Commands', Config.get('Keys', str(value)))
        if command:
            system(command)
            # subprocess.Popen(command, stdout=FNULL, stderr=FNULL, shell=True)
    except Exception as err:
        print err


def parse_socket(is_record, path_cfg_file):
    fetch_config_keys(path_cfg_file)
    with open(SOCKET, "rb") as file:
        event = file.read(EVENT_SIZE)
        try:
            while event:
                (tv_sec, tv_usec, type, code, value) = struct.unpack(FORMAT, event)

                if type != 0 and code != 0 and len(str(value)) > 5:
                    if is_record:
                        record_keys(value)
                    else:
                        exec_command(value)
                event = file.read(EVENT_SIZE)

        except KeyboardInterrupt:
            if is_record:
                with open(path_, "w") as keys_handle:
                    Config.write(keys_handle)

        finally:
            kill_all_processes()


def _argv(args):
    parser = ArgumentParser()
    opt = parser.add_argument
    opt("app", help="")
    opt("-d", "--daemon", help="")
    opt("-r", "--record", help="")
    opt("-c", "--cfg", default=PATH_CONFIG)
    return parser.parse_args(args)


def main(args):
    argv = _argv(args)
    kill_all_processes()
    if argv.record:
        print 'Please click the button to record it.'
        parse_socket(True, argv.cfg)
        return
    if argv.daemon:
        parse_socket(False, argv.cfg)
        return

if __name__ == '__main__':
    main(sys.argv)
