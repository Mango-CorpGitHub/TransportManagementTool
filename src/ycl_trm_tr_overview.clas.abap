"! Entries of a set of transport requests with their comparison against a destination system
"! and their collisions with other requests that are not released
CLASS ycl_trm_tr_overview DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_r_trkorr              TYPE RANGE OF e070-trkorr.
    TYPES ty_t_trkorr              TYPE STANDARD TABLE OF trkorr WITH DEFAULT KEY.
    TYPES ty_e_comparison          TYPE c LENGTH 1.
    TYPES ty_e_not_compared_reason TYPE c LENGTH 20.

    CONSTANTS: BEGIN OF c_comparison,
                 not_requested TYPE ty_e_comparison VALUE space,
                 new           TYPE ty_e_comparison VALUE 'N',
                 equal         TYPE ty_e_comparison VALUE 'E',
                 different     TYPE ty_e_comparison VALUE 'D',
                 not_compared  TYPE ty_e_comparison VALUE 'C',
               END OF c_comparison.

    CONSTANTS: BEGIN OF c_not_compared_reason,
                 customizing     TYPE ty_e_not_compared_reason VALUE 'CUSTOMIZING',
                 deleted         TYPE ty_e_not_compared_reason VALUE 'DELETED',
                 package         TYPE ty_e_not_compared_reason VALUE 'PACKAGE',
                 language        TYPE ty_e_not_compared_reason VALUE 'LANGUAGE',
                 not_versionable TYPE ty_e_not_compared_reason VALUE 'NOT_VERSIONABLE',
                 "! Enhancement (ENHO) without SAP GUI: SAP's comparison needs GUI controls
                 enhancement     TYPE ty_e_not_compared_reason VALUE 'ENHANCEMENT',
               END OF c_not_compared_reason.

    TYPES: BEGIN OF ty_s_entry,
             fragid              TYPE pgmid,
             fragment            TYPE trobjtype,
             fragname            TYPE trobj_name,
             pgmid               TYPE pgmid,
             object              TYPE trobjtype,
             obj_name            TYPE trobj_name,
             objfunc             TYPE objfunc,
             activity            TYPE tractivity,
             lang                TYPE spras,
             keys                TYPE yif_trm_compare_objects=>ty_t_request_keys,
             comparison          TYPE ty_e_comparison,
             not_compared_reason TYPE ty_e_not_compared_reason,
             "! Requests of the set whose entries (or their tasks' entries) contain the object
             requests            TYPE ty_t_trkorr,
             collisions          TYPE ty_t_trkorr,
           END OF ty_s_entry,
           ty_t_entry TYPE STANDARD TABLE OF ty_s_entry WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_overview,
             compared TYPE abap_bool,
             entries  TYPE ty_t_entry,
             messages TYPE bapiret2_t,
           END OF ty_s_overview.

    "! @parameter io_comparer | Comparison with the destination; not supplied: no comparison
    "! @parameter io_collisions | Search of collisions with other requests
    "! @parameter is_collision_with | Filters for the collision search
    METHODS constructor
      IMPORTING io_comparer       TYPE REF TO yif_trm_compare_objects OPTIONAL
                io_collisions     TYPE REF TO yif_trm_get_obj_w_collisions
                is_collision_with TYPE yif_trm_get_obj_w_collisions=>ty_s_collisions_with OPTIONAL.

    "! @parameter it_transport_request | Top-level transport requests
    "! @parameter ir_excluded_requests | Requests ignored as collisions; by default, it_transport_request
    "! @raising ycx_trm_transport_request | The comparison with the destination failed
    METHODS get
      IMPORTING it_transport_request TYPE yif_trm_transport_request=>tab
                ir_excluded_requests TYPE ty_r_trkorr OPTIONAL
      RETURNING VALUE(rs_overview)   TYPE ty_s_overview
      RAISING   ycx_trm_transport_request.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_s_object_request,
             pgmid    TYPE pgmid,
             object   TYPE trobjtype,
             obj_name TYPE trobj_name,
             request  TYPE trkorr,
           END OF ty_s_object_request,
           ty_t_object_request TYPE SORTED TABLE OF ty_s_object_request
                               WITH UNIQUE KEY pgmid object obj_name request.

    DATA ai_o_comparer       TYPE REF TO yif_trm_compare_objects.
    DATA ai_o_collisions     TYPE REF TO yif_trm_get_obj_w_collisions.
    DATA ai_s_collision_with TYPE yif_trm_get_obj_w_collisions=>ty_s_collisions_with.

    METHODS from_comparison
      IMPORTING it_comparison     TYPE yif_trm_compare_objects=>ty_t_comparison
      RETURNING VALUE(rt_entries) TYPE ty_t_entry.

    METHODS from_entries
      IMPORTING it_objects        TYPE yif_trm_tr_object=>tab
      RETURNING VALUE(rt_entries) TYPE ty_t_entry.

    METHODS get_not_compared_reason
      IMPORTING is_comparison    TYPE yif_trm_compare_objects=>ty_s_comparison
      RETURNING VALUE(rv_reason) TYPE ty_e_not_compared_reason.

    METHODS get_collision_objects
      IMPORTING it_entries        TYPE ty_t_entry
                iv_with_fragments TYPE abap_bool
      RETURNING VALUE(rt_objects) TYPE yif_trm_get_obj_w_collisions=>tyt_objects.

    METHODS assign_collisions
      IMPORTING it_collisions TYPE yif_trm_get_obj_w_collisions=>tyt_colisions
      CHANGING  ct_entries    TYPE ty_t_entry.

    METHODS assign_requests
      IMPORTING it_object_requests TYPE ty_t_object_request
      CHANGING  ct_entries         TYPE ty_t_entry.

ENDCLASS.



CLASS ycl_trm_tr_overview IMPLEMENTATION.

  METHOD constructor.
    ai_o_comparer       = io_comparer.
    ai_o_collisions     = io_collisions.
    ai_s_collision_with = is_collision_with.
  ENDMETHOD.


  METHOD get.
    DATA lt_objects         TYPE yif_trm_tr_object=>tab.
    DATA lt_object_requests TYPE ty_t_object_request.

    LOOP AT it_transport_request INTO DATA(lo_transport_request).
      DATA(lv_request) = lo_transport_request->get_code( ).
      LOOP AT lo_transport_request->get_entries( im_include_task_objects = abap_true ) INTO DATA(lo_object).
        INSERT lo_object INTO TABLE lt_objects.
        INSERT VALUE #( pgmid    = lo_object->get_object_id( )
                        object   = lo_object->get_object_type( )
                        obj_name = lo_object->get_object_name( )
                        request  = lv_request ) INTO TABLE lt_object_requests.
      ENDLOOP.
    ENDLOOP.

    IF ai_o_comparer IS BOUND.
      ai_o_comparer->compare( EXPORTING it_objects    = lt_objects
                              IMPORTING et_messages   = rs_overview-messages
                              RECEIVING rt_comparison = DATA(lt_comparison) ).
      rs_overview-compared = abap_true.
      rs_overview-entries  = from_comparison( lt_comparison ).
    ELSE.
      rs_overview-entries = from_entries( lt_objects ).
    ENDIF.

    SORT rs_overview-entries BY pgmid object obj_name.
    DELETE ADJACENT DUPLICATES FROM rs_overview-entries.

    DATA(lr_excluded) = COND ty_r_trkorr(
        WHEN ir_excluded_requests IS SUPPLIED
        THEN ir_excluded_requests
        ELSE VALUE #( FOR lo_request IN it_transport_request
                      ( sign = 'I' option = 'EQ' low = lo_request->get_code( ) ) ) ).

    DATA(lt_collisions) = ai_o_collisions->find(
        it_objects_being_transported = get_collision_objects( it_entries        = rs_overview-entries
                                                              iv_with_fragments = rs_overview-compared )
        ir_tr_being_transported      = CORRESPONDING #( lr_excluded )
        is_collision_with            = ai_s_collision_with ).

    assign_collisions( EXPORTING it_collisions = lt_collisions
                       CHANGING  ct_entries    = rs_overview-entries ).

    assign_requests( EXPORTING it_object_requests = lt_object_requests
                     CHANGING  ct_entries         = rs_overview-entries ).
  ENDMETHOD.


  METHOD from_comparison.
    LOOP AT it_comparison ASSIGNING FIELD-SYMBOL(<ls_comparison>).
      APPEND VALUE #( fragid   = <ls_comparison>-fragid
                      fragment = <ls_comparison>-fragment
                      fragname = <ls_comparison>-fragname
                      pgmid    = <ls_comparison>-pgmid
                      object   = <ls_comparison>-object
                      obj_name = <ls_comparison>-obj_name
                      objfunc  = <ls_comparison>-objfunc
                      activity = <ls_comparison>-activity
                      lang     = <ls_comparison>-lang
                      keys     = <ls_comparison>-keys ) TO rt_entries ASSIGNING FIELD-SYMBOL(<ls_entry>).

      IF <ls_comparison>-not_compared = abap_true.
        <ls_entry>-comparison          = c_comparison-not_compared.
        <ls_entry>-not_compared_reason = get_not_compared_reason( <ls_comparison> ).
      ELSEIF <ls_comparison>-not_comparable = abap_true.
        <ls_entry>-comparison = c_comparison-new.
      ELSEIF <ls_comparison>-equal = abap_true.
        <ls_entry>-comparison = c_comparison-equal.
      ELSE.
        <ls_entry>-comparison = c_comparison-different.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD from_entries.
    rt_entries = VALUE #( FOR lo_object IN it_objects
                          ( pgmid    = lo_object->get_object_id( )
                            object   = lo_object->get_object_type( )
                            obj_name = lo_object->get_object_name( )
                            objfunc  = lo_object->get_function( )
                            activity = lo_object->get_activity( )
                            lang     = lo_object->get_language( ) ) ).
  ENDMETHOD.


  METHOD get_not_compared_reason.
    rv_reason = COND #( WHEN is_comparison-objfunc = yif_trm_tr_object=>function-customizing
                        THEN c_not_compared_reason-customizing
                        WHEN is_comparison-objfunc = yif_trm_tr_object=>function-deleted
                        THEN c_not_compared_reason-deleted
                        WHEN is_comparison-object = 'DEVC'
                        THEN c_not_compared_reason-package
                        WHEN is_comparison-pgmid = 'LANG'
                        THEN c_not_compared_reason-language
                        WHEN is_comparison-object = 'ENHO'
                        THEN c_not_compared_reason-enhancement
                        ELSE c_not_compared_reason-not_versionable ).
  ENDMETHOD.


  METHOD get_collision_objects.
    rt_objects = VALUE #( FOR ls_entry IN it_entries
                          ( pgmid    = ls_entry-pgmid
                            object   = ls_entry-object
                            obj_name = ls_entry-obj_name ) ).

    IF iv_with_fragments = abap_true.
      rt_objects = VALUE #( BASE rt_objects
                            FOR ls_entry IN it_entries
                            ( pgmid    = ls_entry-fragid
                              object   = ls_entry-fragment
                              obj_name = ls_entry-fragname ) ).
    ENDIF.

    SORT rt_objects BY pgmid object obj_name.
    DELETE ADJACENT DUPLICATES FROM rt_objects.
  ENDMETHOD.


  METHOD assign_collisions.
    LOOP AT it_collisions ASSIGNING FIELD-SYMBOL(<ls_collision>).

      ASSIGN ct_entries[ fragid   = <ls_collision>-pgmid
                         fragment = <ls_collision>-object
                         fragname = <ls_collision>-obj_name ] TO FIELD-SYMBOL(<ls_entry>).
      IF sy-subrc = 0.
        INSERT CONV #( <ls_collision>-request ) INTO TABLE <ls_entry>-collisions.
        CONTINUE.
      ENDIF.

      LOOP AT ct_entries ASSIGNING <ls_entry> WHERE     pgmid    = <ls_collision>-pgmid
                                                    AND object   = <ls_collision>-object
                                                    AND obj_name = <ls_collision>-obj_name.
        INSERT CONV #( <ls_collision>-request ) INTO TABLE <ls_entry>-collisions.
      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.


  METHOD assign_requests.
    LOOP AT ct_entries ASSIGNING FIELD-SYMBOL(<ls_entry>).
      <ls_entry>-requests = VALUE #( FOR ls_object_request IN it_object_requests
                                     WHERE (     pgmid    = <ls_entry>-pgmid
                                             AND object   = <ls_entry>-object
                                             AND obj_name = <ls_entry>-obj_name )
                                     ( ls_object_request-request ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
