# Display an overview of all datasets.
function overview() {
    tree -C -lh -L 3 -I "??_trace_ff.npy" -I "???_trace_ff.npy" -I "????_trace_ff.npy" -I "?????_trace_ff.npy" \
                     -I "??_trace_nf.npy" -I "???_trace_nf.npy" -I "????_trace_nf.npy" -I "?????_trace_nf.npy" \
                     . | less
}
