if [ $# -lt 2 ] || [ $1 = "/?" ] || [ $1 = --help ] || [ $1 = -h ]; then
	echo
	echo "libsymbols - generate a CSV of the symbols in your lib files"
	echo "=========="
	echo
	echo "Usage: $0 OBJ_ROOT LIBS..."
	echo
	echo "       OBJ_ROOT - the root directory to search for the .obj files"
	echo "                  that make up the libs in question"
	echo
	echo "       LIBS     - all the .lib files to inspect for symbols"
	exit 1
fi


obj_dir=$1
shift
libs=( `ls $*` )
not_found_n=0
dll_skip_n=0
successful_n=0
for ((lib_i=0; lib_i < ${#libs[@]}; ++lib_i)); do
	lib_path=${libs[$lib_i]} 
	lib=`basename $lib_path`
	>&2 echo $lib [ $(($lib_i + 1)) / ${#libs[@]} ]

	objs=( `lib -nologo -list "$lib_path"` )
	for ((obj_i=0; obj_i < ${#objs[@]}; ++obj_i)); do
		obj=${objs[$obj_i]}
		object=`basename $obj`
		>&2 echo "--> $object [ $(($obj_i + 1)) / ${#objs[@]} ]"

		if [ ${object: -4} == ".dll" ] || [ ${object: -4} == ".DLL" ]; then
			>&2 echo "NOTE: skipping dll"
			let dll_skip_n++
			continue
		fi

		object_path=`find $obj_dir -name $object | head -n1`
		if [ -z $object_path ]; then            # empty string
			>&2 echo "ERROR: can't find $object"
			let not_found_n++
			continue
		fi

		dumpbin -symbols $object_path \
			| grep -v "(\`string')" \
			| grep -o "External *|.*(.*)" \
			| grep -o \(.*\) \
			| sed "s/^(/$lib; $object; /" \
			| sed "s/)$//"

		let successful_n++
	done
	echo ""
done

>&2 echo
>&2 echo "STATUS:"
>&2 echo "    $successful_n obj files successfully scanned for symbols"
if [ $not_found_n -gt 0 ]; then
	>&2 echo "    $not_found_n obj files couldn't be found"
fi
if [ $dll_skip_n -gt 0 ]; then
	>&2 echo "    $dll_skip_n dll files were skipped"
fi
