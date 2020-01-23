db -output /home/x/debug-dashboard
db source -output /home/x/debug-source

db -layout breaks threads stack source
db source -style context 20
db assembly -style context 5
db stack -style limit 8

file ./gizmo
set args test.tcl
set cwd .
set env JIMLIB=../dlr/dlr:../dlr/dlrNative-src
set solib-search-path .:..

#b g_function_info_invoke
#r

#b prepMetaBlob
#b callToGI

db
db

