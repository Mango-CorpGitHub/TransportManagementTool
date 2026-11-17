"! Transport of copies to quality: default selection of the entries of a set of transport
"! requests, entries to copy (whole function groups included) and creation of the request with
"! the customizing keys of the original requests
CLASS ycl_trm_quality_copy DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_e_added_by TYPE c LENGTH 20.

    CONSTANTS: BEGIN OF c_added_by,
                 function_group TYPE ty_e_added_by VALUE 'FUNCTION_GROUP',
               END OF c_added_by.

    CONSTANTS: BEGIN OF c_status,
                 completed TYPE string VALUE `COMPLETED`,
                 failed    TYPE string VALUE `FAILED`,
               END OF c_status.

    CONSTANTS: BEGIN OF c_step,
                 add_objects TYPE string VALUE `ADD_OBJECTS`,
                 release     TYPE string VALUE `RELEASE`,
               END OF c_step.

    "! Entry of the transport of copies (E071 key) with the overview entry it comes from
    TYPES: BEGIN OF ty_s_copy_entry,
             pgmid    TYPE pgmid,
             object   TYPE trobjtype,
             obj_name TYPE trobj_name,
             "! FUNCTION_GROUP if added by the function group rule (overview is then initial)
             added_by TYPE ty_e_added_by,
             overview TYPE ycl_trm_tr_overview=>ty_s_entry,
           END OF ty_s_copy_entry,
           ty_t_copy_entry TYPE STANDARD TABLE OF ty_s_copy_entry WITH EMPTY KEY.

    TYPES: BEGIN OF ty_s_proposal,
             entries  TYPE ty_t_copy_entry,
             excluded TYPE ycl_trm_tr_overview=>ty_t_entry,
           END OF ty_s_proposal.

    TYPES: BEGIN OF ty_s_result,
             request     TYPE trkorr,
             "! COMPLETED or FAILED
             status      TYPE string,
             "! ADD_OBJECTS or RELEASE when FAILED
             failed_step TYPE string,
             released    TYPE abap_bool,
             not_added   TYPE e071_t,
           END OF ty_s_result.

    "! @parameter io_logger | Log where the messages of the copy are added
    METHODS constructor
      IMPORTING io_logger TYPE REF TO yif_trm_logger.

    "! Default selection of an entry ("Add to ToC"): everything without comparison and, with
    "! comparison, everything that is not equal in the destination
    METHODS is_selected_by_default
      IMPORTING iv_compared        TYPE abap_bool
                iv_comparison      TYPE ycl_trm_tr_overview=>ty_e_comparison
      RETURNING VALUE(rv_selected) TYPE abap_bool.

    "! Entries of the copy for the selected overview entries: the fragment if compared, the
    "! entry otherwise, and the whole function group of any selected entry of a function group
    "! (without duplicates)
    METHODS to_copy_entries
      IMPORTING it_selected       TYPE ycl_trm_tr_overview=>ty_t_entry
                iv_compared       TYPE abap_bool
      RETURNING VALUE(rt_entries) TYPE ty_t_copy_entry.

    "! Entries to copy by default and entries excluded (equal in the destination)
    METHODS propose
      IMPORTING is_overview        TYPE ycl_trm_tr_overview=>ty_s_overview
      RETURNING VALUE(rs_proposal) TYPE ty_s_proposal.

    "! Number of different customizing keys of an overview entry
    METHODS get_customizing_key_count
      IMPORTING is_entry        TYPE ycl_trm_tr_overview=>ty_s_entry
      RETURNING VALUE(rv_count) TYPE i.

    "! COPY - &lt;description of the request&gt;, cut to 60 characters
    METHODS get_default_description
      IMPORTING io_request            TYPE REF TO yif_trm_transport_request
      RETURNING VALUE(rv_description) TYPE as4text.

    "! Creates the transport of copies to quality, adds the entries and, if requested, releases
    "! it. The customizing entries take their keys from the original requests; a table content
    "! entry that is not in them is not added. Once the request exists, errors are not raised:
    "! they are returned in the result with the step that failed
    "! @parameter iv_description | Description of the request
    "! @parameter it_transport_request | Original requests (customizing keys, entry attributes)
    "! @parameter it_entries | Entries to copy (R3TR or LIMU)
    "! @parameter iv_release | Release the request after filling it
    "! @raising ycx_trm_transport_request | The request could not be created
    METHODS create
      IMPORTING iv_description       TYPE as4text
                it_transport_request TYPE yif_trm_transport_request=>tab
                it_entries           TYPE e071_t
                iv_release           TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(rs_result)     TYPE ty_s_result
      RAISING   ycx_trm_transport_request.

  PRIVATE SECTION.
    TYPES ty_t_unique_key TYPE SORTED TABLE OF e071k
                          WITH UNIQUE KEY pgmid object objname mastertype mastername viewname tabkey.

    CONSTANTS c_function_group TYPE trobjtype VALUE 'FUGR'.
    CONSTANTS c_r3tr           TYPE pgmid     VALUE 'R3TR'.

    DATA ai_o_logger TYPE REF TO yif_trm_logger.

    METHODS build_objects
      IMPORTING it_transport_request TYPE yif_trm_transport_request=>tab
                it_entries           TYPE e071_t
      EXPORTING et_e071              TYPE e071_t
                et_e071k             TYPE e071k_t
                et_not_added         TYPE e071_t.

    METHODS get_request_entries
      IMPORTING it_transport_request TYPE yif_trm_transport_request=>tab
      RETURNING VALUE(rt_entries)    TYPE yif_trm_tr_object=>tab.

    METHODS find_request_entries
      IMPORTING it_request_entries TYPE yif_trm_tr_object=>tab
                is_entry           TYPE e071
      RETURNING VALUE(rt_entries)  TYPE yif_trm_tr_object=>tab.

    "! The whole function group is itself one of the selected entries
    METHODS is_selected_as_entry
      IMPORTING it_selected        TYPE ycl_trm_tr_overview=>ty_t_entry
                iv_compared        TYPE abap_bool
                iv_obj_name        TYPE trobj_name
      RETURNING VALUE(rv_selected) TYPE abap_bool.

    METHODS is_table_content
      IMPORTING iv_object                  TYPE trobjtype
      RETURNING VALUE(rv_is_table_content) TYPE abap_bool.

    METHODS to_e071k
      IMPORTING io_key          TYPE REF TO yif_trm_tr_custo_entry
      RETURNING VALUE(rs_e071k) TYPE e071k.

    METHODS add_entries
      IMPORTING io_request      TYPE REF TO yif_trm_transport_request
                it_e071         TYPE e071_t
                it_e071k        TYPE e071k_t
      CHANGING  cs_result       TYPE ty_s_result
      RETURNING VALUE(rv_added) TYPE abap_bool.

    METHODS release
      IMPORTING io_request         TYPE REF TO yif_trm_transport_request
      CHANGING  cs_result          TYPE ty_s_result
      RETURNING VALUE(rv_released) TYPE abap_bool.

    METHODS fail
      IMPORTING iv_step   TYPE string
                ix_error  TYPE REF TO cx_root OPTIONAL
      CHANGING  cs_result TYPE ty_s_result.

ENDCLASS.



CLASS ycl_trm_quality_copy IMPLEMENTATION.

  METHOD constructor.
    ai_o_logger = io_logger.
  ENDMETHOD.


  METHOD is_selected_by_default.
    rv_selected = xsdbool(    iv_compared   = abap_false
                           OR iv_comparison <> ycl_trm_tr_overview=>c_comparison-equal ).
  ENDMETHOD.


  METHOD to_copy_entries.
    LOOP AT it_selected ASSIGNING FIELD-SYMBOL(<ls_function_group>) WHERE     pgmid  = c_r3tr
                                                                          AND object = c_function_group.
      IF    line_exists( rt_entries[ pgmid    = <ls_function_group>-pgmid
                                     object   = <ls_function_group>-object
                                     obj_name = <ls_function_group>-obj_name ] )
         OR is_selected_as_entry( it_selected = it_selected
                                  iv_compared = iv_compared
                                  iv_obj_name = <ls_function_group>-obj_name ).
        CONTINUE.
      ENDIF.

      MESSAGE i022(ytrm) WITH <ls_function_group>-obj_name INTO DATA(lv_message) ##NEEDED.
      ai_o_logger->add_from_system_variables( ).

      APPEND VALUE #( pgmid    = <ls_function_group>-pgmid
                      object   = <ls_function_group>-object
                      obj_name = <ls_function_group>-obj_name
                      added_by = c_added_by-function_group ) TO rt_entries.
    ENDLOOP.

    LOOP AT it_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).
      DATA(ls_entry) = COND ty_s_copy_entry( WHEN iv_compared = abap_true
                                             THEN VALUE #( pgmid    = <ls_selected>-fragid
                                                           object   = <ls_selected>-fragment
                                                           obj_name = <ls_selected>-fragname
                                                           overview = <ls_selected> )
                                             ELSE VALUE #( pgmid    = <ls_selected>-pgmid
                                                           object   = <ls_selected>-object
                                                           obj_name = <ls_selected>-obj_name
                                                           overview = <ls_selected> ) ).

      IF line_exists( rt_entries[ pgmid    = ls_entry-pgmid
                                  object   = ls_entry-object
                                  obj_name = ls_entry-obj_name ] ).
        CONTINUE.
      ENDIF.

      APPEND ls_entry TO rt_entries.
    ENDLOOP.
  ENDMETHOD.


  METHOD propose.
    DATA lt_selected TYPE ycl_trm_tr_overview=>ty_t_entry.

    LOOP AT is_overview-entries ASSIGNING FIELD-SYMBOL(<ls_entry>).
      IF is_selected_by_default( iv_compared   = is_overview-compared
                                 iv_comparison = <ls_entry>-comparison ).
        APPEND <ls_entry> TO lt_selected.
      ELSE.
        APPEND <ls_entry> TO rs_proposal-excluded.
      ENDIF.
    ENDLOOP.

    rs_proposal-entries = to_copy_entries( it_selected = lt_selected
                                           iv_compared = is_overview-compared ).
  ENDMETHOD.


  METHOD get_customizing_key_count.
    DATA lt_keys TYPE ty_t_unique_key.

    LOOP AT is_entry-keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      INSERT <ls_key> INTO TABLE lt_keys.
    ENDLOOP.

    rv_count = lines( lt_keys ).
  ENDMETHOD.


  METHOD get_default_description.
    rv_description = |COPY - { io_request->get_description( ) }|.
  ENDMETHOD.


  METHOD create.
    build_objects( EXPORTING it_transport_request = it_transport_request
                             it_entries           = it_entries
                   IMPORTING et_e071              = DATA(lt_e071)
                             et_e071k             = DATA(lt_e071k)
                             et_not_added         = rs_result-not_added ).

    TRY.
        DATA(lo_request) = ycl_trm_transport_request=>create_request(
                               iv_req_desc        = iv_description
                               iv_req_type        = yif_trm_transport_request=>type-toc
                               iv_target          = ycl_trm_transport_request=>get_customizing( )-request_target_system_quality
                               im_o_parent_logger = ai_o_logger ).
      CATCH ycx_trm_transport_request INTO DATA(lx_create).
        ai_o_logger->add_exception( im_o_exception = lx_create
                                    im_type        = yif_trm_logger=>msgty-error ).
        RAISE EXCEPTION lx_create.
    ENDTRY.

    rs_result-request = lo_request->get_code( ).

    IF add_entries( EXPORTING io_request = lo_request
                              it_e071    = lt_e071
                              it_e071k   = lt_e071k
                    CHANGING  cs_result  = rs_result ) = abap_false.
      RETURN.
    ENDIF.

    IF iv_release = abap_true.
      IF release( EXPORTING io_request = lo_request
                  CHANGING  cs_result  = rs_result ) = abap_false.
        RETURN.
      ENDIF.
    ENDIF.

    rs_result-status = c_status-completed.
  ENDMETHOD.


  METHOD build_objects.
    DATA lt_keys TYPE ty_t_unique_key.

    CLEAR: et_e071,
           et_e071k,
           et_not_added.

    DATA(lt_request_entries) = get_request_entries( it_transport_request ).

    LOOP AT it_entries ASSIGNING FIELD-SYMBOL(<ls_entry>).
      IF    line_exists( et_e071[ pgmid    = <ls_entry>-pgmid
                                  object   = <ls_entry>-object
                                  obj_name = <ls_entry>-obj_name ] )
         OR line_exists( et_not_added[ pgmid    = <ls_entry>-pgmid
                                       object   = <ls_entry>-object
                                       obj_name = <ls_entry>-obj_name ] ).
        CONTINUE.
      ENDIF.

      DATA(lt_matches) = find_request_entries( it_request_entries = lt_request_entries
                                               is_entry           = <ls_entry> ).

      IF lt_matches IS INITIAL.
        IF is_table_content( <ls_entry>-object ).
          MESSAGE w023(ytrm) WITH <ls_entry>-pgmid <ls_entry>-object <ls_entry>-obj_name
                  INTO DATA(lv_message) ##NEEDED.
          ai_o_logger->add_from_system_variables( ).
          APPEND VALUE #( pgmid    = <ls_entry>-pgmid
                          object   = <ls_entry>-object
                          obj_name = <ls_entry>-obj_name ) TO et_not_added.
        ELSE.
          APPEND VALUE #( pgmid    = <ls_entry>-pgmid
                          object   = <ls_entry>-object
                          obj_name = <ls_entry>-obj_name ) TO et_e071.
        ENDIF.
        CONTINUE.
      ENDIF.

      DATA(lo_first) = lt_matches[ 1 ].
      DATA(ls_e071) = VALUE e071( pgmid    = <ls_entry>-pgmid
                                  object   = <ls_entry>-object
                                  obj_name = <ls_entry>-obj_name
                                  objfunc  = lo_first->get_function( )
                                  activity = lo_first->get_activity( )
                                  lang     = lo_first->get_language( ) ).

      LOOP AT lt_matches INTO DATA(lo_match).
        IF lo_match->is_customizing( ) = abap_false.
          CONTINUE.
        ENDIF.
        ls_e071-objfunc = yif_trm_tr_object=>function-customizing.
        LOOP AT lo_match->get_custo_entries( ) INTO DATA(lo_key).
          INSERT to_e071k( lo_key ) INTO TABLE lt_keys.
        ENDLOOP.
      ENDLOOP.

      APPEND ls_e071 TO et_e071.
    ENDLOOP.

    et_e071k = lt_keys.
  ENDMETHOD.


  METHOD get_request_entries.
    LOOP AT it_transport_request INTO DATA(lo_request).
      INSERT LINES OF lo_request->get_entries( im_include_task_objects = abap_true ) INTO TABLE rt_entries.
    ENDLOOP.
  ENDMETHOD.


  METHOD find_request_entries.
    LOOP AT it_request_entries INTO DATA(lo_entry).
      IF     lo_entry->get_object_id( )   = is_entry-pgmid
         AND lo_entry->get_object_type( ) = is_entry-object
         AND lo_entry->get_object_name( ) = is_entry-obj_name.
        INSERT lo_entry INTO TABLE rt_entries.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD is_selected_as_entry.
    IF iv_compared = abap_false.
      rv_selected = abap_true.
      RETURN.
    ENDIF.

    rv_selected = xsdbool( line_exists( it_selected[ fragid   = c_r3tr
                                                     fragment = c_function_group
                                                     fragname = iv_obj_name ] ) ).
  ENDMETHOD.


  METHOD is_table_content.
    rv_is_table_content = xsdbool(    iv_object = 'TABU'
                                   OR iv_object = 'TDAT'
                                   OR iv_object = 'VDAT'
                                   OR iv_object = 'CDAT' ).
  ENDMETHOD.


  METHOD to_e071k.
    rs_e071k = VALUE #( pgmid      = io_key->get_object_id( )
                        object     = io_key->get_object_type( )
                        objname    = io_key->get_object_name( )
                        as4pos     = io_key->get_position( )
                        mastertype = io_key->get_master_type( )
                        mastername = io_key->get_master_name( )
                        viewname   = io_key->get_view_name( )
                        tabkey     = io_key->get_tab_key( )
                        sortflag   = io_key->get_sort_flag( )
                        flag       = io_key->get_flag( )
                        lang       = io_key->get_language( )
                        activity   = io_key->get_activity( ) ).
  ENDMETHOD.


  METHOD add_entries.
    TRY.
        io_request->lock( ).
        io_request->add_objects( EXPORTING im_t_e071       = it_e071
                                           im_t_e071k      = it_e071k
                                 IMPORTING ex_t_not_added  = DATA(lt_not_added) ).
        io_request->unlock( ).
      CATCH ycx_trm_transport_request INTO DATA(lx_add).
        io_request->unlock( ).
        fail( EXPORTING iv_step   = c_step-add_objects
                        ix_error  = lx_add
              CHANGING  cs_result = cs_result ).
        RETURN.
    ENDTRY.

    INSERT LINES OF lt_not_added INTO TABLE cs_result-not_added.

    IF io_request->get_entries( ) IS INITIAL.
      fail( EXPORTING iv_step   = c_step-add_objects
            CHANGING  cs_result = cs_result ).
      RETURN.
    ENDIF.

    rv_added = abap_true.
  ENDMETHOD.


  METHOD release.
    TRY.
        io_request->release( im_check_released = abap_true ).
      CATCH ycx_trm_transport_request INTO DATA(lx_release).
        fail( EXPORTING iv_step   = c_step-release
                        ix_error  = lx_release
              CHANGING  cs_result = cs_result ).
        RETURN.
    ENDTRY.

    IF io_request->is_released( ) = abap_false.
      fail( EXPORTING iv_step   = c_step-release
            CHANGING  cs_result = cs_result ).
      RETURN.
    ENDIF.

    cs_result-released = abap_true.
    rv_released        = abap_true.
  ENDMETHOD.


  METHOD fail.
    cs_result-status      = c_status-failed.
    cs_result-failed_step = iv_step.
    IF ix_error IS BOUND.
      ai_o_logger->add_exception( im_o_exception = ix_error
                                  im_type        = yif_trm_logger=>msgty-error ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
