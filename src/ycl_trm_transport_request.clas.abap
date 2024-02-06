CLASS ycl_trm_transport_request DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES yif_trm_transport_request .

    METHODS constructor
      IMPORTING
        !im_code     TYPE trkorr
        !im_o_logger TYPE REF TO yif_trm_logger
      RAISING
        ycx_trm_transport_request .
    CLASS-METHODS get_by_code
      IMPORTING
        !im_code                      TYPE trkorr
        !im_o_parent_logger           TYPE REF TO yif_trm_logger OPTIONAL
      RETURNING
        VALUE(re_o_transport_request) TYPE REF TO yif_trm_transport_request
      RAISING
        ycx_trm_transport_request .
    CLASS-METHODS get_by_attributes
      IMPORTING
        !im_s_query_by_attr           TYPE yif_trm_transport_request_db=>typ_s_tr_query_by_attr
        !im_s_load_cache_params       TYPE yif_trm_transport_request_db=>typ_s_load_cache_params OPTIONAL
        !im_o_parent_logger           TYPE REF TO yif_trm_logger OPTIONAL
      RETURNING
        VALUE(re_t_transport_request) TYPE yif_trm_transport_request=>tab
      RAISING
        ycx_trm_transport_request .
    CLASS-METHODS get_by_description
      IMPORTING
        !im_s_query_by_description    TYPE yif_trm_transport_request_db=>typ_s_tr_query_by_description
        !im_s_query_by_attr           TYPE yif_trm_transport_request_db=>typ_s_tr_query_by_attr OPTIONAL
        !im_o_parent_logger           TYPE REF TO yif_trm_logger OPTIONAL
      RETURNING
        VALUE(re_t_transport_request) TYPE yif_trm_transport_request=>tab
      RAISING
        ycx_trm_transport_request .
    CLASS-METHODS load_cache
      IMPORTING
        !im_t_codes             TYPE yif_trm_transport_request_db=>typ_t_code
        !im_s_load_cache_params TYPE yif_trm_transport_request_db=>typ_s_load_cache_params
        !im_language            TYPE sy-langu DEFAULT sy-langu .
    CLASS-METHODS clear_cache .
    CLASS-METHODS get_customizing
      RETURNING
        VALUE(rs_customizing) TYPE yif_trm_transport_request_db=>ty_s_customizing
      RAISING
        ycx_trm_transport_request .
    CLASS-METHODS create_request
      IMPORTING
        !iv_user                      TYPE tr_as4user DEFAULT sy-uname
        !iv_req_desc                  TYPE as4text
        !iv_req_type                  TYPE trfunction
        !iv_target                    TYPE tr_target OPTIONAL
        !im_o_parent_logger           TYPE REF TO yif_trm_logger OPTIONAL
      EXPORTING
        !et_messages                  TYPE ymdg_t_transport_message
        !ev_trkorr                    TYPE trkorr
      RETURNING
        VALUE(re_o_transport_request) TYPE REF TO yif_trm_transport_request
      RAISING
        ycx_trm_transport_request .
  PROTECTED SECTION.
    DATA:
      ai_code  TYPE trkorr,

      ai_o_log TYPE REF TO yif_trm_logger.

    CLASS-METHODS get_db_interface
      RETURNING
        VALUE(re_o_db_interface) TYPE REF TO yif_trm_transport_request_db.

    METHODS transport_request_exception IMPORTING textid                   LIKE if_t100_message=>t100key OPTIONAL
                                                  previous                 TYPE REF TO cx_root OPTIONAL
                                                  msgty                    TYPE symsgty DEFAULT yif_trm_logger=>msgty-error
                                                    PREFERRED PARAMETER textid
                                        RETURNING VALUE(re_x_tr_exception) TYPE REF TO ycx_trm_transport_request.


  PRIVATE SECTION.
    DATA as_o_db_interface TYPE REF TO yif_trm_transport_request_db.

ENDCLASS.



CLASS YCL_TRM_TRANSPORT_REQUEST IMPLEMENTATION.


  METHOD yif_trm_transport_request~unlock.

    CALL FUNCTION 'DEQUEUE_E_TRKORR'
      EXPORTING
        trkorr = ai_code.

  ENDMETHOD.


  METHOD yif_trm_transport_request~release.

    " First: Release all tasks
    DATA(lt_task) = me->yif_trm_transport_request~get_tasks(  ).
    IF im_release_tasks EQ abap_true AND lines( lt_task ) > 0.

      LOOP AT lt_task ASSIGNING FIELD-SYMBOL(<lo_task>).
        <lo_task>->release(  ).
      ENDLOOP.

    ENDIF.

    DATA(lv_trokrr) = me->yif_trm_transport_request~get_code( ).
    " Second: Release Transport Request
    CALL FUNCTION 'TRINT_RELEASE_REQUEST'
      EXPORTING
        iv_trkorr                  = lv_trokrr
        iv_dialog                  = space
        iv_without_locking         = abap_true
      EXCEPTIONS
        cts_initialization_failure = 1
        enqueue_failed             = 2
        no_authorization           = 3
        invalid_request            = 4
        request_already_released   = 5
        repeat_too_early           = 6
        error_in_export_methods    = 7
        object_check_error         = 8
        docu_missing               = 9
        db_access_error            = 10
        action_aborted_by_user     = 11
        export_failed              = 12
        OTHERS                     = 13.

    IF sy-subrc IS INITIAL.
*      ai_o_log->info( |{ lv_trokrr } has been released| ).
    ELSE.
      ai_o_log->warning( |{ lv_trokrr } could not be released| ).
      RETURN.
    ENDIF.

    IF im_check_released EQ abap_false.
      RETURN.
    ENDIF.

    " Check if Transport Request is released
    DO.

      IF yif_trm_transport_request~is_released(  ).

        ai_o_log->info( |{ lv_trokrr } has been released| ).
        RETURN.

      ENDIF.

    ENDDO.

  ENDMETHOD.


  METHOD yif_trm_transport_request~lock.

    CALL FUNCTION 'ENQUEUE_E_TRKORR'
      EXPORTING
        trkorr         = ai_code
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2.
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION transport_request_exception( ycx_trm_transport_request=>is_locked ).
    ENDIF.

  ENDMETHOD.


  METHOD yif_trm_transport_request~is_task.
    re_is_task = COND #( WHEN as_o_db_interface->fetch_data( me )-transportrequestparentid IS INITIAL
                         THEN abap_false
                         ELSE abap_true
                       ).
  ENDMETHOD.


  METHOD yif_trm_transport_request~is_released.

    as_o_db_interface->set_ignore_cache( abap_true ).

    re_is_released = COND #( WHEN yif_trm_transport_request~get_status( ) EQ yif_trm_transport_request=>status-release OR
                                  yif_trm_transport_request~get_status( ) EQ yif_trm_transport_request=>status-release_with_import_protection
                             THEN abap_true
                             ELSE abap_false
                           ).

    as_o_db_interface->set_ignore_cache( abap_false ).

  ENDMETHOD.


  METHOD yif_trm_transport_request~get_type.
    re_type = as_o_db_interface->fetch_data( me )-transportrequesttype.
  ENDMETHOD.


  METHOD yif_trm_transport_request~get_tasks.
    DATA(lt_task) = ycl_trm_transport_request=>get_by_attributes( im_s_query_by_attr = VALUE #( parentid = VALUE #( ( sign = 'I' option = 'EQ' low = me->ai_code ) ) ) ).

    re_t_task = VALUE #( FOR task IN lt_task ( NEW ycl_trm_tr_task(
                                                     im_code            = task->get_code( )
                                                     im_o_parent_logger = ai_o_log
                                                    )
                                             )
                       ).

  ENDMETHOD.


  METHOD yif_trm_transport_request~get_target.
    re_target = as_o_db_interface->fetch_data( me )-transportrequesttarget.
  ENDMETHOD.


  METHOD yif_trm_transport_request~get_status.
    re_status = as_o_db_interface->fetch_data( me )-transportrequeststatus.
  ENDMETHOD.


  METHOD yif_trm_transport_request~get_owner.
    DATA: ls_address TYPE bapiaddr3,
          lt_return  TYPE STANDARD TABLE OF bapiret2.

    CLEAR: ex_name.

    re_owner = as_o_db_interface->fetch_data( me )-transportrequestowner.

    CALL FUNCTION 'BAPI_USER_GET_DETAIL'
      EXPORTING
        username = re_owner
      IMPORTING
        address  = ls_address
      TABLES
        return   = lt_return.

    IF ls_address IS NOT INITIAL.
      ex_name = ls_address-fullname.
    ENDIF.

  ENDMETHOD.


  METHOD yif_trm_transport_request~get_last_change_time.
    re_last_change_time = as_o_db_interface->fetch_data( me )-lastchangetime.
  ENDMETHOD.


  METHOD yif_trm_transport_request~get_last_change_date.
    re_last_change_date = as_o_db_interface->fetch_data( me )-lastchangedate.
  ENDMETHOD.


  METHOD yif_trm_transport_request~get_entry.
    re_o_entry = NEW ycl_trm_tr_object(
      im_code           = ai_code
      im_position       = im_position
      im_o_log          = ai_o_log
      im_o_db_interface = get_db_interface(  )
    ).
  ENDMETHOD.


  METHOD yif_trm_transport_request~get_entries.

    DATA(lt_entries) = as_o_db_interface->fetch_entries( im_o_transport_request = me ).

    re_t_entries = VALUE #( FOR entry IN lt_entries
                            ( yif_trm_transport_request~get_entry( entry-transportrequestposition ) )
                          ).

    IF im_include_task_objects EQ abap_true.

      re_t_entries = VALUE #( BASE re_t_entries FOR task IN yif_trm_transport_request~get_tasks(  )
                                                FOR entry_task IN task->yif_trm_transport_request~get_entries(  )
                                                ( entry_task )
                            ).


    ENDIF.

  ENDMETHOD.


  METHOD yif_trm_transport_request~get_description.
    DATA(lt_description) = as_o_db_interface->fetch_text( me ).

    IF lt_description IS INITIAL.
      RETURN.
    ENDIF.

    ASSIGN lt_description[ language = im_language ] TO FIELD-SYMBOL(<description>).
    IF sy-subrc IS INITIAL.
      re_description = <description>-description.
    ELSE.
      re_description = lt_description[ 1 ]-description.
    ENDIF.

  ENDMETHOD.


  METHOD yif_trm_transport_request~get_code.
    re_code = ai_code.
  ENDMETHOD.


  METHOD yif_trm_transport_request~get_category.
    re_category = as_o_db_interface->fetch_data( me )-transportrequestcategory.
  ENDMETHOD.


  METHOD yif_trm_transport_request~add_to_queue.

    DATA(ls_customzing) = get_customizing( ).

    DATA(lv_destination) = COND #(
*                                   WHEN iv_system = yif_trm_transport_request=>system-development THEN ls_customzing-rfc_to_quality
                                   WHEN im_system = yif_trm_transport_request=>system-quality    THEN ls_customzing-rfc_to_quality
                                   WHEN im_system = yif_trm_transport_request=>system-production THEN ls_customzing-rfc_to_productive ).

    DATA(lv_system) = COND tmscsys-sysnam(
                                   WHEN im_system = yif_trm_transport_request=>system-development THEN sy-sysid
                                   WHEN im_system = yif_trm_transport_request=>system-quality     THEN ls_customzing-request_target_system_quality(3)
*                                   WHEN iv_system = yif_trm_transport_request=>system-production THEN ls_customzing-rfc_to_productive
                                    ).

*    call function 'TMS_MGR_GREP_TRANSPORT_QUEUE'
*      EXPORTING
*        iv_system  = lv_system
*        iv_request = ai_code
*      EXCEPTIONS
*        read_config_failed       = 1
*        read_import_queue_failed = 2
*        others                   = 3
*      .
*    IF SY-SUBRC <> 0.
**     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*    ENDIF.

    " Add TR to Development queue
    CALL FUNCTION 'TMS_MGR_FORWARD_TR_REQUEST'
      EXPORTING
        iv_request      = ai_code
        iv_target       = lv_system
        iv_tarcli       = sy-mandt
        iv_source       = lv_system
        iv_import_again = abap_true
        iv_monitor      = abap_true
        iv_verbose      = space
      EXCEPTIONS
        OTHERS          = 99.
    IF sy-subrc <> 0.
      ai_o_log->add_from_system_variables( ).
      transport_request_exception( ).
    ENDIF.

  ENDMETHOD.


  METHOD yif_trm_transport_request~add_objects.

    DATA lt_trmess_int TYPE STANDARD TABLE OF trmess_int WITH DEFAULT KEY.

    DATA(lt_e071) = VALUE e071_t( FOR transport_request IN im_t_transport_request
                                   FOR object IN transport_request->get_entries( im_include_task_objects = abap_true )
                                   ( pgmid = object->get_object_id(  )
                                     object = object->get_object_type(  )
                                     obj_name = object->get_object_name(  )
                                     objfunc = object->get_function(  )
                                     activity = object->get_activity( )
                                   )
                                 ).

    IF im_t_e071 IS NOT INITIAL.
      APPEND LINES OF im_t_e071 TO lt_e071.
    ENDIF.

    DELETE lt_e071 WHERE pgmid = 'CORR'.

    DATA(lt_e071k) = VALUE e071k_t( FOR transport_request IN im_t_transport_request
                                     FOR object IN transport_request->get_entries( im_include_task_objects = abap_true )
                                      FOR custo IN object->get_custo_entries(  )
                                      ( pgmid      = custo->get_object_id(  )
                                        object     = custo->get_object_type( )
                                        objname    = custo->get_object_name( )
                                        as4pos     =  custo->get_position( )
                                        mastertype = custo->get_master_type( )
                                        mastername = custo->get_master_name( )
                                        viewname   = custo->get_view_name( )
*                                        OBJFUNC    = custo->get_
                                        tabkey     = custo->get_tab_key(  )
                                        sortflag   = custo->get_sort_flag( )
                                        flag       = custo->get_flag( )
                                        lang       = custo->get_language(  )
                                        activity   = custo->get_activity(  )
                                      )
                                  ).

    IF im_t_e071k IS NOT INITIAL.
      APPEND LINES OF im_t_e071k TO lt_e071k.
    ENDIF.

    " Si no hay errores el módulo de función sólo se ejecutara una vez
    " Si hay errores, en la segunda ejecución descartamos aquellos objetos
    " que han fallado y lo llamamos de nuevo sin ellos
    DO 2 TIMES.

      CALL FUNCTION 'TRINT_APPEND_TO_COMM_ARRAYS'
        EXPORTING
          wi_error_table               = 'X'
          wi_trkorr                    = me->yif_trm_transport_request~get_code( )
          wi_suppress_key_check        = 'X'
          iv_append_at_order           = 'X'
          iv_append_at_order_with_lock = ' '
        TABLES
          wt_e071                      = lt_e071
          wt_e071k                     = lt_e071k
          wt_trmess_int                = lt_trmess_int
        EXCEPTIONS
          key_check_keysyntax_error    = 1
          ob_check_obj_error           = 2
          tr_lockmod_failed            = 3
          tr_lock_enqueue_failed       = 4
          tr_wrong_order_type          = 5
          tr_order_update_error        = 6
          file_access_error            = 7
          ob_no_systemname             = 8
          OTHERS                       = 9.

      IF sy-subrc IS INITIAL.
        ai_o_log->info( |{ lines( lt_e071 ) } objects has been added to Transport Request| ).
        RETURN.
      ELSE.
        ai_o_log->warning( |The following objects has not been added to Transport Request| ).
        LOOP AT lt_trmess_int ASSIGNING FIELD-SYMBOL(<ls_trmess_int>).

          ai_o_log->warning( |{ <ls_trmess_int>-msgv1 } / { <ls_trmess_int>-msgv2 } / { <ls_trmess_int>-msgv3 }| ).

          DELETE lt_e071 WHERE pgmid    = <ls_trmess_int>-msgv1  AND
                               object   = <ls_trmess_int>-msgv2  AND
                               obj_name = <ls_trmess_int>-msgv3.
          IF sy-subrc IS NOT INITIAL.
            DELETE lt_e071 WHERE obj_name = <ls_trmess_int>-msgv1.
          ENDIF.

          DELETE lt_e071k WHERE pgmid    = <ls_trmess_int>-msgv1  AND
                                object   = <ls_trmess_int>-msgv2  AND
                                objname  = <ls_trmess_int>-msgv3.
        ENDLOOP.
      ENDIF.

    ENDDO.

  ENDMETHOD.


  METHOD transport_request_exception.
    re_x_tr_exception = NEW ycx_trm_transport_request(
      textid    = textid
      previous  = previous
      msgty     = yif_trm_logger=>msgty-error
      code      = ai_code
      logger    = ai_o_log
    ).
  ENDMETHOD.


  METHOD load_cache.
    get_db_interface( )->load_cache(
      EXPORTING
        im_t_codes             = im_t_codes
        im_s_load_cache_params = im_s_load_cache_params ).
  ENDMETHOD.


  METHOD get_db_interface.
    re_o_db_interface = ycl_trm_transport_request_db=>create( ).
  ENDMETHOD.


  METHOD get_customizing.
    rs_customizing = get_db_interface( )->fetch_customizing( ).

    IF rs_customizing-request_target_system_quality IS INITIAL.
      RAISE EXCEPTION NEW ycx_trm_transport_request( textid = ycx_trm_transport_request=>customizing_missing_in_stvarvc
                                                     customizing_name = yif_trm_transport_request_db=>c_customizing-request_target_quality_name ).
    ENDIF.

    IF rs_customizing-rfc_to_productive IS INITIAL.
      RAISE EXCEPTION NEW ycx_trm_transport_request( textid = ycx_trm_transport_request=>customizing_missing_in_stvarvc
                                                     customizing_name = yif_trm_transport_request_db=>c_customizing-rfc_to_productive_name ).
    ENDIF.

    IF rs_customizing-rfc_to_quality IS INITIAL.
      RAISE EXCEPTION NEW ycx_trm_transport_request( textid = ycx_trm_transport_request=>customizing_missing_in_stvarvc
                                                     customizing_name = yif_trm_transport_request_db=>c_customizing-rfc_to_quality_name ).
    ENDIF.

    IF rs_customizing-request_target_system_dev IS INITIAL.
      RAISE EXCEPTION NEW ycx_trm_transport_request( textid = ycx_trm_transport_request=>customizing_missing_in_stvarvc
                                                     customizing_name = yif_trm_transport_request_db=>c_customizing-request_target_dev_name ).
    ENDIF.

  ENDMETHOD.


  METHOD get_by_description.

    DATA(lt_codes) = get_db_interface(  )->query_tr_by_description( im_s_query_by_description ).
    IF NOT line_exists( lt_codes[ 1 ] ).
      RETURN.
    ENDIF.

    DATA(ls_query_by_attr) = im_s_query_by_attr.
    ls_query_by_attr-code = lt_codes.

    re_t_transport_request = get_by_attributes( im_s_query_by_attr = ls_query_by_attr ).

  ENDMETHOD.


  METHOD get_by_code.
    re_o_transport_request = NEW ycl_trm_transport_request(
      im_code            = im_code
      im_o_logger = im_o_parent_logger
    ).
  ENDMETHOD.


  METHOD get_by_attributes.

    DATA(lt_codes) = get_db_interface(  )->query_tr_data_by_attr( im_s_query_by_attr ).

    DATA(lt_data) = get_db_interface(  )->fetch_data_list( lt_codes ).

    re_t_transport_request = VALUE #( FOR data IN lt_data ( ycl_trm_transport_request=>get_by_code( im_code = data-code
                                                                                                    im_o_parent_logger = im_o_parent_logger
                                                                                                   )
                                                           )
                                    ).

    IF im_s_load_cache_params IS NOT INITIAL.
      load_cache(
        EXPORTING
          im_t_codes             = lt_codes
          im_s_load_cache_params = im_s_load_cache_params
*            im_language            = SY-LANGU
      ).
    ENDIF.
  ENDMETHOD.


  METHOD create_request.

    DATA: lt_users   TYPE STANDARD TABLE OF scts_user,
          ls_request TYPE trwbo_request_header.

    APPEND iv_user TO lt_users.

    CALL FUNCTION 'TR_INSERT_REQUEST_WITH_TASKS'
      EXPORTING
        iv_type           = iv_req_type
        iv_text           = iv_req_desc
        iv_target         = iv_target
        it_users          = lt_users
      IMPORTING
        es_request_header = ls_request
      EXCEPTIONS
        insert_failed     = 1
        OTHERS            = 2.

    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION TYPE ycx_trm_transport_request.
    ENDIF.

    ev_trkorr = ls_request-trkorr.
    re_o_transport_request = ycl_trm_transport_request=>get_by_code( im_code = ev_trkorr
                                                                     im_o_parent_logger = im_o_parent_logger
                                                                   ).

  ENDMETHOD.


  METHOD constructor.
    ai_o_log = im_o_logger.
    ai_code = im_code.
    as_o_db_interface = get_db_interface( ).

    IF NOT as_o_db_interface->check_exists( me ).
      RAISE EXCEPTION transport_request_exception( ycx_trm_transport_request=>not_exists ).
    ENDIF.
  ENDMETHOD.


  METHOD clear_cache.
    get_db_interface(  )->clear_cache(  ).
  ENDMETHOD.

  METHOD yif_trm_transport_request~delete_entry.

    DATA(ls_request) = VALUE trwbo_request( h = value #( trkorr = yif_trm_transport_request~get_code(  ) ) ).

    CALL FUNCTION 'TR_DELETE_COMM_OBJECT_KEYS'
      EXPORTING
        is_e071_delete              = VALUE e071( trkorr   = yif_trm_transport_request~get_code(  )
                                                  pgmid    = im_o_entry->get_object_id( )
                                                  object   = im_o_entry->get_object_type( )
                                                  obj_name = im_o_entry->get_object_name( )
                                                )
        iv_dialog_flag              = space
      CHANGING
        cs_request                  = ls_request
      EXCEPTIONS
        e_database_access_error     = 1
        e_empty_lockkey             = 2
        e_bad_target_request        = 3
        e_wrong_source_client       = 4
        n_no_deletion_of_c_objects  = 5
        n_no_deletion_of_corr_entry = 6
        n_object_entry_doesnt_exist = 7
        n_request_already_released  = 8
        n_request_from_other_system = 9
        r_action_aborted_by_user    = 10
        r_foreign_lock              = 11
        w_bigger_lock_in_same_order = 12
        w_duplicate_entry           = 13
        w_no_authorization          = 14
        w_user_not_owner            = 15
        OTHERS                      = 16.
    IF sy-subrc IS NOT INITIAL.
        RAISE EXCEPTION transport_request_exception( ycx_trm_transport_request=>entry_not_deleted ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
