"Restituisce la testata di una tabella ddic
GET_HEADER_FROM_DDIC    using    XV_TAB_NAME type STRING
                        changing YV_HEADER   type STRING .
                     
"Restituisce una tabella di stringhe separate da ;                     
UPLOAD_LOCAL_EXCEL      using    XV_FILENAME    type STRING
                                 XV_HEADER      type FLAG
                        changing YT_FILE_STRING type STRING_TABLE .
 
 "Restituisce una tabella di stringhe
 UPLOAD_LOCAL_CSV       using    XV_FILENAME    type STRING
                        changing YT_FILE_STRING type STRING_TABLE .

"Fornisce help per selezionare directory locale o server
HELP_F4_INPUT_DIR       using    X_OPTION type CHAR1
                                 XV_TITLE type STRING optional
                                 XV_DIR   type STRING .
                                 
 "Restituisce la directory locale del desktop
 GET_LOCAL_DESKTOP_DIR  changing XV_DIR   type STRING .