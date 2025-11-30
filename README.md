Design Sources' Hierarchy
    npu_top
        cnn_top
            cnn_1
            cnn_2
        fc
            fc_mac_array
        comparator

1st cnn layer --> stride=4; pooling=2x2,max; kernels=4x4,6;
2nd cnn layer --> stride=1; pooling=2x2,max; kernels=2x2,12;
fc --> output_dim=10;
