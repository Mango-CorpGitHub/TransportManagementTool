"! Compares the entries of transport requests with their active version in a destination system
INTERFACE yif_trm_compare_objects
  PUBLIC.

  TYPES ty_t_request_keys TYPE STANDARD TABLE OF e071k WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_s_comparison.
           INCLUDE TYPE vrs_compare_item.
  TYPES:   objfunc      TYPE char01,
           activity     TYPE string,
           not_compared TYPE abap_bool,
           keys         TYPE ty_t_request_keys,
           lang         TYPE spras,
         END OF ty_s_comparison.
  TYPES ty_t_comparison TYPE STANDARD TABLE OF ty_s_comparison WITH DEFAULT KEY.

  "! Compares the objects with the destination system
  "! @parameter it_objects | Transport request entries
  "! @parameter et_messages | Warnings that did not stop the comparison
  "! @parameter rt_comparison | Comparison by object and fragment
  "! @raising ycx_trm_transport_request | Communication error with the destination
  METHODS compare
    IMPORTING it_objects           TYPE yif_trm_tr_object=>tab
    EXPORTING et_messages          TYPE bapiret2_t
    RETURNING VALUE(rt_comparison) TYPE ty_t_comparison
    RAISING   ycx_trm_transport_request.

ENDINTERFACE.
