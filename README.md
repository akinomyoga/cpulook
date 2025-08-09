# `cpulook`

A set of scripts to monitor uses of multiple hosts.  The assumed
installation path of these scripts is fixed to be
`~/.local/share/cpulook`.  You need to clone the repository exactly at
this location.

```console
$ mkdir -p ~/.local/share
$ git clone git@github.com:akinomyoga/cpulook.git ~/.local/share/cpulook
```

Another way is to run the script `install.sh` after cloning. It will
copy necessary files into `~/.local/share/cpulook`.

```console
$ git clone git@github.com:akinomyoga/cpulook.git
$ cd cpulook
$ ./install.sh
```

## Configuration

- `cpulist.cfg`

To set up hosts, one first needs to copy `cpulist-default.cfg` to
`cpulist.cfg` and edit the file to add the currently avaiable hosts.
Then, one needs to define the way to access the hosts in the `hosts`
subdirectory.  To register a host that can be accessible through
`ssh`, one can create a symbolic link to `ssh` at
`hosts/<hostname>.sh`.

```console
$ cd hosts
$ ln -s 'ssh' '<hostname>.sh'
```

## Commands

- `cpulook`

- `cpusub [options] command`

- `cpuseekd [options]`

- `cputop HOST`

- `cpups HOST`

- `cpulast HOST`

- `cpukill CPUJOBID`
