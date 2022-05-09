class ZCL_ZCDLG_API_APPROVE_DPC_EXT definition
  public
  inheriting from ZCL_ZCDLG_API_APPROVE_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~EXECUTE_ACTION
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZCDLG_API_APPROVE_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~execute_action.

DATA: ls_return TYPE zcl_zcdlg_api_approve_mpc=>result.

CASE iv_action_name.
  WHEN 'EXE_DECISION'.
      ls_return-code = '666'.
      ls_return-text = 'To be defined'.
ENDCASE.



* Call method copy_data_to_ref and export entity set data
          copy_data_to_ref( EXPORTING is_data = ls_return
                  CHANGING cr_data = er_data ).

  ENDMETHOD.
ENDCLASS.
