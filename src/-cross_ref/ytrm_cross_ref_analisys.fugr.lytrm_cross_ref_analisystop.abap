FUNCTION-POOL ytrm_cross_ref_analisys.      " MESSAGE-ID ..

DATA lt_objs                 TYPE STANDARD TABLE OF cnvcdmccts_objects_set WITH DEFAULT KEY.
DATA rfc_compare_destination TYPE rfcdest.
DATA result                  TYPE ycl_trm_cross_ref_analisys=>ty_s_return.
DATA alv_viewer              TYPE REF TO ycl_trm_cross_ref_analisys_alv.
DATA alv_container           TYPE REF TO cl_gui_custom_container.

* INCLUDE LYTRM_CROSS_REF_ANALISYSD...       " Local class definition
