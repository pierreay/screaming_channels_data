# Display an overview of all datasets.
function overview() {
    tree -C -lh -I "??_trace_ff.npy" -I "???_trace_ff.npy" -I "????_trace_ff.npy" -I "?????_trace_ff.npy" \
                -I "??_trace_nf.npy" -I "???_trace_nf.npy" -I "????_trace_nf.npy" -I "?????_trace_nf.npy" \
                . | less
}
