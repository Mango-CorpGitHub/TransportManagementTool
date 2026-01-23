INTERFACE yif_trm_cross_reference
  PUBLIC.

  TYPES tab         TYPE STANDARD TABLE OF REF TO yif_trm_cross_reference WITH DEFAULT KEY.

  TYPES ty_e_status TYPE c LENGTH 100.
  CONSTANTS: BEGIN OF c_status,
               also_in_transport_request     TYPE ty_e_status VALUE 'Also in transport request',
               only_in_source                TYPE ty_e_status VALUE 'Only in Source',
               exist_in_destination          TYPE ty_e_status VALUE 'Exist in destination',
               sap_reference                 TYPE ty_e_status VALUE 'SAP Reference',
               equal_in_destination          TYPE ty_e_status VALUE 'Equal in destination',
               different_in_destination      TYPE ty_e_status VALUE 'Different in destination',
               method_definition_dif_in_dest TYPE ty_e_status VALUE 'Method definition different in destination',
               only_in_destination           TYPE ty_e_status VALUE 'Only in destination',
               different_but_not_relevant    TYPE ty_e_status VALUE 'Different but not relevant',
               different                     TYPE ty_e_status VALUE 'Different',
               definition_missing            TYPE ty_e_status VALUE 'Definition Missing',

               " Intern status
               subobject_not_assigned        TYPE ty_e_status VALUE 'INTERNAL - SubObject not assigned',
               to_delete                     TYPE ty_e_status VALUE 'INTERNAL - To Delete',
             END OF c_status.

  TYPES: BEGIN OF ty_s_object,
           pgmid    TYPE pgmid,
           type     TYPE trobjtype,
           name     TYPE trobj_name,
           severity TYPE icon-name,
           logger   TYPE REF TO yif_trm_logger,
         END OF ty_s_object,
         ty_t_object TYPE STANDARD TABLE OF ty_s_object WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_s_reference_object,
           reference_fragid   TYPE pgmid,
           reference_fragment TYPE trobjtype,
           reference_fragname TYPE trobj_name,
           status             TYPE ty_e_status,
         END OF ty_s_reference_object.

  TYPES: BEGIN OF ty_s_result,
           reference_fragid     TYPE pgmid,
           reference_fragment   TYPE trobjtype,
           reference_fragname   TYPE trobj_name,
           status               TYPE ty_e_status,
           sub_reference_object TYPE STANDARD TABLE OF ty_s_reference_object WITH DEFAULT KEY,
           object_list          TYPE ty_t_object,
         END OF ty_s_result.

  TYPES: BEGIN OF ty_s_comparison,
           name     TYPE string,
           type     TYPE string,
           severity TYPE icon-name,
           status   TYPE yif_trm_cross_reference=>ty_e_status,
         END OF ty_s_comparison,
         ty_t_comparison TYPE STANDARD TABLE OF ty_s_comparison WITH DEFAULT KEY.


  METHODS get_data RETURNING VALUE(rs_data) TYPE ty_s_result.

  METHODS exists
    IMPORTING iv_rfc_destination TYPE rfcdes-rfcdest OPTIONAL
    RETURNING VALUE(rv_exists)   TYPE abap_bool
    RAISING   cx_method_not_implemented.

  METHODS navigate
    RAISING ycx_trm_transport_request.

  METHODS compare
    IMPORTING iv_rfc_destination   TYPE rfcdes-rfcdest
    RETURNING VALUE(rt_comparison) TYPE ty_t_comparison
    RAISING   cx_method_not_implemented.

ENDINTERFACE.
