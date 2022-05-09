class ZCL_Z_ALERT_RECEIPT_DPC_EXT definition
  public
  inheriting from ZCL_Z_ALERT_RECEIPT_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~EXECUTE_ACTION
    redefinition .
protected section.

  methods POITEMTORECEIPTS_GET_ENTITY
    redefinition .
  methods VALUEHELPSET_GET_ENTITYSET
    redefinition .
private section.

  methods GET_STORAGELOC_LIST
    importing
      !IV_FILTER type FILTNAME
      !IT_SELECT_OPTIONS type /IWBEP/T_COD_SELECT_OPTIONS optional
      !IV_SEARCH type STRING optional
    exporting
      !ET_VALUE type ZCL_Z_ALERT_RECEIPT_MPC=>TT_VALUEHELP .
ENDCLASS.



CLASS ZCL_Z_ALERT_RECEIPT_DPC_EXT IMPLEMENTATION.


  METHOD /IWBEP/IF_MGW_APPL_SRV_RUNTIME~EXECUTE_ACTION.
**TRY.
*CALL METHOD SUPER->/IWBEP/IF_MGW_APPL_SRV_RUNTIME~EXECUTE_ACTION
**  EXPORTING
**    IV_ACTION_NAME          =
**    IT_PARAMETER            =
**    IO_TECH_REQUEST_CONTEXT =
**  IMPORTING
**    ER_DATA                 =
*    .
** CATCH /IWBEP/CX_MGW_BUSI_EXCEPTION .
** CATCH /IWBEP/CX_MGW_TECH_EXCEPTION .
**ENDTRY.

    DATA: lt_bapiret2       TYPE bapiret2_tty.
    DATA: ls_message_http   TYPE ihttpnvp,
          ls_parameter      TYPE /iwbep/s_mgw_name_value_pair,
          ls_bapiret2       TYPE bapiret2,
*          ls_return_message TYPE zcl_zpr_approval_mpc=>returnmessage,

          ls_return_approve TYPE bapiret2.
    DATA: lv_workitem   TYPE sww_wiid,
          lv_newdatets  TYPE timestamp,
          lv_newdate    TYPE slfdt,
          lv_quantity   TYPE string,
          lv_qty        TYPE etmen,
          lv_finalentry TYPE flag,
          lv_date       TYPE sy-datum.

    IF it_parameter IS NOT INITIAL.
* Read Function import parameter value
      READ TABLE it_parameter INTO ls_parameter WITH KEY name = 'WorkItemId'.
      IF sy-subrc = 0.
        lv_workitem = ls_parameter-value.
      ENDIF.
    ENDIF.


    CASE iv_action_name.
      WHEN 'set_new_date'.
        READ TABLE it_parameter INTO ls_parameter
                                WITH KEY name = 'NewDate'.
        IF sy-subrc = 0.
          lv_newdatets = ls_parameter-value.


          CONVERT TIME STAMP lv_newdatets TIME ZONE sy-zonlo
                    INTO DATE lv_date.


          CALL METHOD /cdlg/wf02_eket=>ext_wf_actions
            EXPORTING
*             iv_etmen      = lv_qty
              iv_new_date   = lv_date
*             iv_elikz      =
              iv_sww_wiid   = lv_workitem
              iv_action     = 'D'
              iv_user       = sy-uname
*             iv_lgort      =
            RECEIVING
              rv_sww_wistat = lv_workitem.

        ENDIF.




      WHEN 'set_final_delivery'.

          lv_finalentry = 'X'.

        IF lv_finalentry IS NOT INITIAL.
          CALL METHOD /cdlg/wf02_eket=>ext_wf_actions
            EXPORTING
*             iv_etmen      = lv_qty
*             iv_new_date   = lv_date
              iv_elikz      = lv_finalentry
              iv_sww_wiid   = lv_workitem
              iv_action     = 'F'
              iv_user       = sy-uname
*             iv_lgort      =
            RECEIVING
              rv_sww_wistat = lv_workitem.
        ENDIF.




      WHEN 'set_gr'.
        READ TABLE it_parameter INTO ls_parameter
                               WITH KEY name = 'Quantity'.
        IF sy-subrc = 0.
          lv_quantity = ls_parameter-value.
        ENDIF.
        READ TABLE it_parameter INTO ls_parameter
                               WITH KEY name = 'FinalDelivery'.
        IF sy-subrc = 0.
          lv_finalentry = ls_parameter-value.
        ENDIF.

        IF lv_quantity IS NOT INITIAL.

          SHIFT lv_quantity LEFT DELETING LEADING space.
          move lv_quantity to lv_qty.

          CALL METHOD /cdlg/wf02_eket=>ext_wf_actions
            EXPORTING
              iv_etmen      = lv_qty
*             iv_new_date   = lv_date
              iv_elikz      = lv_finalentry
              iv_sww_wiid   = lv_workitem
              iv_action     = 'G'
              iv_user       = sy-uname
*             iv_lgort      =
            RECEIVING
              rv_sww_wistat = lv_workitem.


        ENDIF.


      WHEN OTHERS.
    ENDCASE.

*Return result: (Populate from BAPIRET2 returned by Jonathan
IF  ls_bapiret2-number NE '601'.
*    ls_return_message-code = ls_bapiret2-number.
*    ls_return_message-type = ls_bapiret2-type.
*    ls_return_message-text = ls_bapiret2-message.

endif.
*    copy_data_to_ref(
*          EXPORTING
*            is_data = ls_return_message
*          CHANGING
*            cr_data = er_data ).

  ENDMETHOD.


  METHOD get_storageloc_list.

     TYPES : BEGIN OF lty_lgort,
      lgort TYPE t001l-lgort,
      lgobe TYPE t001l-lgobe,
             END OF lty_lgort.
DATA : lt_lgort TYPE TABLE OF lty_lgort.


  SELECT lgort lgobe FROM t001l INTO TABLE lt_lgort WHERE werks = iv_filter.

  LOOP AT lt_lgort ASSIGNING FIELD-SYMBOL(<wa>).
      IF iv_search IS NOT INITIAL.
        IF <wa>-lgort NS iv_search AND <wa>-lgobe NS iv_search.
          CONTINUE.
        ENDIF.
      ENDIF.

      APPEND INITIAL LINE TO et_value ASSIGNING FIELD-SYMBOL(<value>).
      <value>-key = <wa>-lgort.
      <value>-description_1 = <wa>-lgobe.
      <value>-secondary_value = <wa>-lgobe.
  ENDLOOP.


  ENDMETHOD.


  METHOD POITEMTORECEIPTS_GET_ENTITY.

    DATA : lt_keys   TYPE /iwbep/t_mgw_tech_pairs,
           lt_return TYPE TABLE OF bapiret2.

    DATA : ls_key      TYPE /iwbep/s_mgw_tech_pair.
    DATA : lv_wiid           TYPE sww_wiid,
           lv_date           TYPE timestamp,
           lv_new_deliv_date TYPE sy-datum.
    DATA : ls_schedule TYPE meposchedule,
           ls_item     TYPE mepoitem,
           ls_header   TYPE mepoheader.

    DATA : lv_msg TYPE symsgv.
    DATA : ls_lfa1 TYPE lfa1,
           ls_adrc TYPE adrc,
           ls_adr6 TYPE adr6.

    DATA : lo_message_container TYPE REF TO /iwbep/if_message_container.

    DATA : ls_swwwihead TYPE swwwihead.
    CONSTANTS: lc_wiid      TYPE string VALUE 'SWW_WIID'.

    lo_message_container = mo_context->get_message_container( ).
    lt_keys = io_tech_request_context->get_keys( ).
    IF lt_keys IS INITIAL.
      " Navigation source entity set
      lt_keys = io_tech_request_context->get_source_keys( ).
    ENDIF.

    LOOP AT lt_keys INTO ls_key.
      CASE ls_key-name.
        WHEN lc_wiid.
          lv_wiid = ls_key-value.
      ENDCASE.
    ENDLOOP.

    CHECK lv_wiid IS NOT INITIAL.

    SELECT SINGLE * INTO ls_swwwihead
                    FROM swwwihead
             WHERE wi_id = lv_wiid
               AND wi_type = 'W'.
*               AND wi_stat = 'READY'.
    IF sy-subrc NE 0.
      lv_msg = lv_wiid.
      CALL METHOD lo_message_container->add_message
        EXPORTING
          iv_msg_type   = 'E'
          iv_msg_id     = 'MEPO'
          iv_msg_number = 601
*         iv_msg_text   =
          iv_msg_v1     = 'Erreur lors du traitement de ce workitem : '
          iv_msg_v2     = lv_msg
*         iv_msg_v3     =
*         iv_msg_v4     =
        .
      RETURN.
    ENDIF.

    CLEAR lv_new_deliv_date.
    CALL METHOD /cdlg/wf02_eket=>ext_get_data
      EXPORTING
        iv_sww_wiid          = lv_wiid
      IMPORTING
        es_meposchedule      = ls_schedule
        es_mepoitem          = ls_item
        es_mepoheader        = ls_header
        ev_new_delivery_date = lv_new_deliv_date.



    MOVE ls_schedule-ebeln TO er_entity-ebeln.
    MOVE ls_schedule-ebelp TO er_entity-ebelp.
    MOVE ls_schedule-etenr TO er_entity-etenr.
    MOVE lv_wiid           TO er_entity-sww_wiid.

    SELECT SINGLE * FROM lfa1
           INTO ls_lfa1 WHERE lifnr = ls_header-lifnr.
    IF sy-subrc EQ 0.
      SELECT * FROM adrc INTO ls_adrc
                      UP TO 1 ROWS WHERE addrnumber EQ ls_lfa1-adrnr.
      ENDSELECT.
      SELECT * FROM adr6 INTO ls_adr6
                      UP TO 1 ROWS WHERE addrnumber EQ ls_lfa1-adrnr.
      ENDSELECT.
      er_entity-smtp_addr  = ls_adr6-smtp_addr.
      er_entity-ad_tlnmbr1 = ls_adrc-tel_number.
      er_entity-ad_city1   = ls_adrc-city1.
      er_entity-ad_pstcd1  = ls_adrc-post_code1.
      er_entity-ad_hsnm1   = ls_adrc-house_num1.
      er_entity-ad_street  = ls_adrc-street.
      er_entity-name_org1  = ls_adrc-name1.
    ENDIF.





    MOVE ls_header-lifnr   TO er_entity-lifnr.


    CALL FUNCTION 'FRE_CONVERT_DATE_TO_TIMESTMP'
      EXPORTING
        ip_start_date    = ls_header-aedat
      IMPORTING
        ep_start_date    = lv_date
      EXCEPTIONS
        conversion_error = 1
        OTHERS           = 2.
    IF sy-subrc EQ 0.
      er_entity-erdat   = lv_date.
    ELSE.
      CLEAR er_entity-erdat.
    ENDIF.


    IF lv_new_deliv_date IS NOT INITIAL.
      CALL FUNCTION 'FRE_CONVERT_DATE_TO_TIMESTMP'
        EXPORTING
          ip_start_date    = lv_new_deliv_date
        IMPORTING
          ep_start_date    = lv_date
        EXCEPTIONS
          conversion_error = 1
          OTHERS           = 2.
      IF sy-subrc EQ 0.
        er_entity-new_deldate   = lv_date.
      ELSE.
        CLEAR er_entity-new_deldate.
      ENDIF.
    ENDIF.

    MOVE ls_header-ernam   TO er_entity-ernam.
    IF ls_header-ekorg IS NOT INITIAL.
      SELECT SINGLE ekotx INTO er_entity-ekotx
        FROM t024e
        WHERE ekorg = ls_header-ekorg.
    ENDIF.

    MOVE ls_header-ekorg   TO er_entity-ekorg.
    IF NOT ls_header-bukrs IS INITIAL.
      SELECT SINGLE butxt INTO er_entity-butxt
             FROM t001
             WHERE bukrs EQ ls_header-bukrs.
    ENDIF.
    MOVE ls_header-bukrs   TO er_entity-bukrs.
    IF NOT ls_item-werks IS INITIAL.
      SELECT SINGLE name1 INTO er_entity-name1
             FROM t001w
             WHERE werks = ls_item-werks.
    ENDIF.
    MOVE ls_item-werks     TO er_entity-werks.
    MOVE ls_item-matnr     TO er_entity-matnr.

    IF NOT ls_item-matkl IS INITIAL.
      SELECT SINGLE wgbez INTO er_entity-wgbez
             FROM t023t
             WHERE spras = sy-langu
               AND matkl = ls_item-matkl.
    ENDIF.
    MOVE ls_item-matkl     TO er_entity-matkl.
    IF NOT ls_item-lgort IS INITIAL.
      SELECT SINGLE lgobe INTO er_entity-lgobe
             FROM t001l
             WHERE werks = ls_item-werks
               AND lgort = ls_item-lgort.
    ENDIF.
    MOVE ls_item-lgort     TO er_entity-lgort.
    MOVE ls_schedule-menge TO er_entity-menge.
    MOVE ls_schedule-obmng TO er_entity-obmng.
    MOVE ls_item-meins TO er_entity-meins.
    MOVE ls_item-pstyp TO er_entity-pstyp.
    IF ls_item-pstyp is INITIAL.
      er_entity-pstyp = '0'.
    ENDIF.

    CALL FUNCTION 'FRE_CONVERT_DATE_TO_TIMESTMP'
      EXPORTING
        ip_start_date    = ls_schedule-slfdt
      IMPORTING
        ep_start_date    = lv_date
      EXCEPTIONS
        conversion_error = 1
        OTHERS           = 2.
    IF sy-subrc EQ 0.
      er_entity-slfdt   = lv_date.
    ELSE.
      CLEAR er_entity-slfdt.
    ENDIF.

    MOVE ls_item-txz01     TO er_entity-txz01.







  ENDMETHOD.


  method VALUEHELPSET_GET_ENTITYSET.

    DATA lt_filter_select_options	TYPE /iwbep/t_mgw_select_option.
    DATA ls_filter_select_options	TYPE /iwbep/s_mgw_select_option.
    DATA lv_property_name LIKE ls_filter_select_options-property.
    DATA lt_select_options TYPE /iwbep/t_cod_select_options.
    DATA ls_select_options TYPE /iwbep/s_cod_select_option.
    DATA lv_type TYPE text50.
    DATA : lv_filter TYPE filtname,
           lv_search TYPE String.

    lt_filter_select_options = it_filter_select_options[].

* Filter
    LOOP AT it_filter_select_options INTO ls_filter_select_options.
      lv_property_name = ls_filter_select_options-property.
      TRANSLATE lv_property_name TO UPPER CASE.
      CASE lv_property_name.
        WHEN 'TYPE'.
          lt_select_options = ls_filter_select_options-select_options.
          READ TABLE lt_select_options INDEX 1 INTO ls_select_options.
          lv_type = ls_select_options-low.
        WHEN 'FILTER'.
          lt_select_options = ls_filter_select_options-select_options.
          READ TABLE lt_select_options INDEX 1 INTO ls_select_options.
          lv_filter = ls_select_options-low.
        WHEN 'FILTER1'.
          lt_select_options = ls_filter_select_options-select_options.
          READ TABLE lt_select_options INDEX 1 INTO ls_select_options.
          lv_search = ls_select_options-low.
        WHEN OTHERS.
      ENDCASE.
    ENDLOOP.

    CASE lv_type.
      WHEN 'StorageLoc'.
            me->get_storageloc_list( EXPORTING iv_filter = lv_filter iv_search = lv_search IMPORTING et_value = et_entityset ).
    ENDCASE.

    LOOP AT et_entityset ASSIGNING FIELD-SYMBOL(<lfs_entity>).
      <lfs_entity>-type = lv_type.
    ENDLOOP.


  endmethod.
ENDCLASS.
