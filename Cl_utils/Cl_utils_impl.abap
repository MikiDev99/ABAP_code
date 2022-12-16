* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>GET_HEADER_FROM_DDIC
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_TAB_NAME                    TYPE        STRING
* | [<---] YV_HEADER                      TYPE        STRING
* +-------------------------------------------------------------------------------------------------+
  FORM get_header_from_ddic using    XV_TAB_NAME TYPE STRING
                            changing YV_HEADER   TYPE STRING.
                            
    DATA: lv_details       TYPE abap_compdescr_tab,
          lv_ref_table_des TYPE REF TO cl_abap_structdescr,
          lt_type          TYPE TABLE OF dfies.

    "Prendo i nomi dei campi della tabella
    "-------------------------------------------------
    lv_ref_table_des ?=
        cl_abap_typedescr=>describe_by_name( xv_tab_name ).
    lv_details[] = lv_ref_table_des->components[].

    CHECK lv_details IS NOT INITIAL.

    "Prendo le etichette dei campi della tabella
    "-------------------------------------------------
    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = xv_tab_name
        langu          = sy-langu
      TABLES
        dfies_tab      = lt_type
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      "Implement suitable error handling here
    ENDIF.

    "Costruisco l'intestazione
    "-------------------------------------------------
    LOOP AT lt_type ASSIGNING FIELD-SYMBOL(<fieldname>).

      IF yv_header IS INITIAL.
        yv_header = <fieldname>-fieldtext.
      ELSE.
        yv_header = yv_header &&  ';' && <fieldname>-fieldtext.
      ENDIF.

    ENDLOOP.
  ENDFORM.
  
* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>UPLOAD_LOCAL_EXCEL
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_FILENAME                    TYPE        STRING
* | [--->] XV_HEADER                      TYPE        FLAG
* | [<---] YT_FILE_STRING                 TYPE        STRING_TABLE
* +-------------------------------------------------------------------------------------------------+    
FORM upload_local_excel using     XV_FILENAME    TYPE STRING
                                  XV_HEADER      TYPE FLAG
                        changing  YT_FILE_STRING TYPE STRING_TABLE.

    DATA: lv_filename TYPE rlgrap-filename,
          lv_sytabix  TYPE sy-tabix,
          lv_end_row  TYPE i,
          lv_end_col  TYPE i.

    DATA: lt_intern       TYPE TABLE OF alsmex_tabline,
          lt_intern_index TYPE TABLE OF alsmex_tabline.

    FIELD-SYMBOLS: <intern> LIKE LINE OF lt_intern,
                   <index>  LIKE LINE OF lt_intern,
                   <file>   LIKE LINE OF yt_file_string.

    lv_filename = xv_filename.

    IF lv_filename CS '.xlsx'.

      lv_end_row = 1048576.
      lv_end_col = 16384 .

    ELSEIF lv_filename CS '.xls'.

      lv_end_row = 65536.
      lv_end_col = 256.

    ELSE.
      MESSAGE s646(db) WITH TEXT-e02 DISPLAY LIKE 'E'.
*      STOP.
    ENDIF.

    "-------------------------------------------------
    REFRESH lt_intern[].
    CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
      EXPORTING
        filename                = lv_filename
        i_begin_col             = 1
        i_begin_row             = 1
        i_end_col               = lv_end_col
        i_end_row               = lv_end_row
      TABLES
        intern                  = lt_intern[]
      EXCEPTIONS
        inconsistent_parameters = 1
        upload_ole              = 2
        OTHERS                  = 3.
    IF sy-subrc <> 0.
      MESSAGE s646(db) WITH TEXT-e03 DISPLAY LIKE 'E'.
*      STOP.
    ENDIF.

    IF xv_header EQ 'X'.
      DELETE lt_intern WHERE row = 1.
    ENDIF.

    IF lt_intern IS INITIAL.
      MESSAGE s646(db) WITH TEXT-e04 DISPLAY LIKE 'W'.
*      STOP.
    ENDIF.

    SORT lt_intern BY row col.
    lt_intern_index[] = lt_intern[].
    DELETE ADJACENT DUPLICATES FROM lt_intern_index COMPARING row.

    REFRESH yt_file_string.
    LOOP AT lt_intern_index ASSIGNING <index>.

      READ TABLE lt_intern TRANSPORTING NO FIELDS BINARY SEARCH
        WITH KEY row = <index>-row.
      CHECK sy-subrc EQ 0.
      lv_sytabix = sy-tabix.

      APPEND INITIAL LINE TO yt_file_string ASSIGNING <file>.
      LOOP AT lt_intern ASSIGNING <intern> FROM lv_sytabix.
        IF <intern>-row NE <index>-row.
          EXIT.
        ENDIF.

        IF <file> IS INITIAL.
          <file> = <intern>-value.
        ELSE.
          <file> = <file> && ';' && <intern>-value.
        ENDIF.

      ENDLOOP.

    ENDLOOP.
  ENDFORM.
  
* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>UPLOAD_LOCAL_CSV
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_FILENAME                    TYPE        STRING
* | [<---] YT_FILE_STRING                 TYPE        STRING_TABLE
* +-------------------------------------------------------------------------------------------------+  
  FORM upload_local_csv using    XV_FILENAME    TYPE STRING
                        changing YT_FILE_STRING	TYPE STRING_TABLE.

    REFRESH yt_file_string[].
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename                = xv_filename
        filetype                = 'ASC'
      TABLES
        data_tab                = yt_file_string
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        OTHERS                  = 17.
    IF sy-subrc <> 0.

    ENDIF.

  ENDFORM.
  
* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>HELP_F4_INPUT_DIR
* +-------------------------------------------------------------------------------------------------+
* | [--->] X_OPTION                       TYPE        CHAR1
* | [--->] XV_TITLE                       TYPE        STRING(optional)
* | [<---] YV_DIR                         TYPE        STRING
* +-------------------------------------------------------------------------------------------------+ 
 FORM help_f4_input_dir using X_OPTION  TYPE CHAR1
                              XV_TITLE  TYPE STRING OPTIONAL
                              YV_DIR    TYPE STRING.

    "Ricordati lo user command nei radio button
    CASE x_option.

      WHEN 'L'.

        CALL METHOD cl_gui_frontend_services=>directory_browse
          EXPORTING
            window_title    = xv_title
            initial_folder  = yv_dir
          CHANGING
            selected_folder = yv_dir.

      WHEN 'S'.

        "Selezionre cartella da server
        CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE'
          EXPORTING
            directory        = yv_dir
            filemask         = '?'
          IMPORTING
            serverfile       = yv_dir
          EXCEPTIONS
            canceled_by_user = 1
            OTHERS           = 2.
        IF sy-subrc <> 0.

        ENDIF.

      WHEN OTHERS.
    ENDCASE.

  ENDFORM. 

* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>GET_LOCAL_DESKTOP_DIR
* +-------------------------------------------------------------------------------------------------+
* | [<---] XV_DIR                         TYPE        STRING
* +-------------------------------------------------------------------------------------------------+
FORM get_local_desktop_dir CHANGING xv_dir.
    CALL METHOD cl_gui_frontend_services=>get_desktop_directory
      CHANGING
        desktop_directory = xv_dir
      EXCEPTIONS
        cntl_error        = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
ENDFORM.
    CALL METHOD cl_gui_cfw=>update_view.
