# 'bootstrap assist' module.
# 'bootstrap assist' module.
# _.fns - utility functions to assist in bootstrap of uts.v1 utilities.
# necessary as uts.xxx.shi files (utility function groups) have a strict 
# dependency order to enable their use in isolation - without other uts.xxx.shi
# files on which they depend.

declare -g ___uts___

if test -z $___uts___; then
	___uts___='already-included'

	_.eval() 
	# tbd - enhance with 'security' of eval stuff.
	# e.g. - only use 'preconfigured' templates... etc.
	{
		eval "$@";
	}

	_.err() { >&2 echo $*; }
	_.errcat() 
	{ 
		if ! test -f $1 || test -z $1; then
			_.errexit "_.errcat: no such file or no file arg (\$1=<$1>) - bye!";
		else
			>&2 cat $1;
		fi
	}
	_.abort() { local stackfile=$(_.stack); _.errcat $stackfile; _.err "aborting... $*";  _.err;  _.exit 1; }
	_.fnname() { local level=${1:-0}; level=$((level + 1)); echo "${FUNCNAME[$level]}"; }
	_.progerr() { _.abort '...programming error detected - function:' $(_.br $(_.fnname 1)) ' ...' $*; }
	_.isnull() { test -z "$1"; }

	_.echo_return() { _.eval "$@"; local result=$?; echo $result; }
	_.noerr.flag() { echo --noerr; }

	_.arg() 
	{
		local noerr=1;
		if test $1 == $(_.noerr.flag); then
			noerr=0;
			shift;
		fi	

		_.isnull "$*";
		local null=$?

		if $null && ! $noerr; then
			_.abort "argument error in $(_.fnname) - missing value for argument"; 
		fi; 
		if $null && $noerr; then
			return 1;
		fi

		echo "$@"; 
	}

	_.env.var()
	{
		local varname=$(_.arg $1);
		local default=$2; test -z $default; local usedefault=$?;
		local varvalue=${!varname};

		if test -z $varvalue && ! $usedefault; then
			_progerr "env var <$varname> is not set, & no default provided"
		fi
		if test -z $varvalue && $usedefault; then
			varvalue=$default;
		fi			
		echo $varvalue;
	}

	### AROUND HERE!
	
	_.pre.default( echo ${UTS_PREFIX_DEFAULT:-uts}; );
	_.suf.default( echo ${UTS_SUFFIX_DEFAULT:-shi}; );

	_.const.pre.flag() { echo '--pre'; }
	_.const.suf.flag() { echo '--suf'; }
	
	_.default()
	{
		local value=$(_.arg $1);
		local pre=$(_.const.pre.flag);
		local suf=$(_.const.suf.flag);
		local opts=$(_.cat $pre '|' $suf);
		
		if test $1 == $pre; then
			_.pre.default;		
		elif test $1 == $suf; then
			_.suf.default;
		else
			_.progerr "unknown option as \$1:<$value> must use: <$opts>"
		fi
	}

	_.prefix() { local pre=${UTS_PREFIX:-$(_.default --pre)}; echo $UTS_PREFIX; }
	_.suffix() { echo .shi; }

	_.stack()
	{
		local i=0;
		local fnname=$(_.fnname $i);
		local tmp=$(mktemp);
		(
			echo 'stack trace:'
			while test $fnname != main; do
				i=$((i+1));
				fnname=$(_.fnname $i)
				echo "stack($i): $fnname"
			done
		) > $tmp;
		echo $tmp
	}


	_.debug() { return 0; }
	_.dbg() { if _.debug; then _.err $*; fi; }

	_.br() { echo "<$*>"; }
	_.isfn() { test $(type -t "$1") = 'function'; }
	_.count() { echo $#; }


	uts.rmchars() 
	{ 
		local str=$(_.arg $1); shift; 

		local res=$(echo $* | sed "s?$str??g"); 
		echo $res
	}

	_.rmdot() { echo $* | sed 's/\.//g'; }
	_.rmspace() { echo $* | sed 's/ //g'; }
	_.rmslash() { _.rmchars '/' $*; }
	_.rmdash() { _.rmchars '-' $*; }
	_.cat() { _.rmspace $*; }
	
	_.randstr() { echo $(_.cat RAND_ $(_.rmdot $(_.rmslash $(mktemp /tmp/candelete_XXXXXXXXXXXXXXXXXXX))) ); };

	_.modname()
	{ 
		local str=$(basename $(_.arg $1));
		local pre=$(_.prefix);
		local suf=$(_.suffix);

		echo $str | sed "s/$pre//g" | sed "s/$suf//g";
	}

	_.fnconst()
	{
		local name=$(_.arg $1);
		local val=$2;
		if _.isnull $val; then val=$name; fi

		local fntemplate="
			$name()
			{
				echo $val;
			}
		";
		_.eval "$fntemplate";
	}

	_.fnbody()
	{
		local fn=$(_.arg $1);

		if ! _.isfn $fn; then
			_.abort "not a function $(_.br $fn)";
		fi

		local body=$( declare -f $fn | grep -v $fn | grep -v '{' | grep -v '}' );
		echo "$body"
	}

	_.fnclone()
	{
		local from=$(_.arg $1);
		local to=$(_.arg $2);

		local fnbody=$(_.fnbody $from);

		local fntemplate="
			function $to()
			{
				$fnbody ;
			}
		"
		eval $fntemplate;
	}

	_.fngetset()
	{
		local varname=$(_arg $1);
		local value=$2;

		local private_global=$(_randstr);

		local fntemplate="
			$varname()
			{
				declare -g $private;

				if test \$# == 0;  then
					echo $private_global;
				else
					$private_global=$value;
				fi
			}
		"
		_.eval $fntempate
	}

	_.fnconst flag.getset --getset
	
	_.fnrefprivate()
	{
		local flag=$(flag.getset);
		local opt=$(_.arg $1);
		local dogetset=1;

		if test $opt == $gsflag; then
			dogetset=0;
			shift;
		fi

		local name=$(_arg $1);
		local value=$(_.randstr);

		if !dogetset; then
			_.fnconst $name $value
		else

	}

	_.contained_in()
	{
		local value=$(_.arg $1);
		shift;

		local i;
		for i in "$@"; do
			if test $value == $i; then
				return 0;
			fi
		done
		return 1;
	}

	err() { _.err $*; } # todo: remove.

	_.set() {  set -o | grep $1.*on >/dev/null 2>/dev/null; }

	_fnconst flag.off --off
	
	_.strict() 
	{	
		if test $1  == $(flag.off); then
			set +u;
		else
			set -u;
		fi
	}
	
	_.strict;
fi