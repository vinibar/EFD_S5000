*&---------------------------------------------------------------------*
*& Report       YHRBR_EFD_S5000_REPORT
*& Descrição    Totalizadores eSocial para eventos de folha
*&            (S-5001 e S-5002)
*&---------------------------------------------------------------------*
*&
*& Autor: Vinicius Barrionuevo (Solutio IT)
*& Data: 01/08/2018
*&
*&---------------------------------------------------------------------*

report  yhrbr_efd_tot_pay_report.

tables: pernr.

parameters: p_5001 type c radiobutton group g1.
parameters: p_5002 type c radiobutton group g1.

include yhrbr_efd_tot_report_cd.
include yhrbr_efd_tot_report_ci.

data o_app type ref to lcl_app.
data o_selection type ref to lcl_selection.

initialization.

  o_app = lcl_app=>get_instance( ).

start-of-selection.

  o_selection = o_app->get_selection( ).

  o_selection->set_begda( pn-begda ).
  o_selection->set_endda( pn-endda ).
  o_selection->set_event_type( ).

get pernr.
  o_selection->set_pernr( pernr-pernr ).


end-of-selection.

  o_app->main( ).



*----------------------------------------------------------------------*
*  MODULE pbo_9000 OUTPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
module pbo_9000 output.

  o_app->pbo( ).

endmodule.                    "pbo_9000 OUTPUT

*----------------------------------------------------------------------*
*  MODULE pai_9000 INPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
module pai_9000 input.

  o_app->pai( sy-ucomm ).

endmodule.                    "pai_9000 INPUT

*----------------------------------------------------------------------*
*  MODULE exit INPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
module exit input.

  o_app->exit( sy-ucomm ).

endmodule.                    "exit INPUT
