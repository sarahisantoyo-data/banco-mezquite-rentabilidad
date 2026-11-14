Attribute VB_Name = "ExportarTablasCSV"
Sub ExportarTablasCSV()
    Dim tablas As Variant, nombre As Variant
    Dim carpeta As String, lo As ListObject
    Dim libroNuevo As Workbook, col As Range

    ' 1. Carpeta destino: ...\Proyecto_Banca_Rentabilidad\datos\limpios\
    carpeta = Left(ThisWorkbook.Path, InStrRev(ThisWorkbook.Path, "\")) & "datos\limpios\"

    ' 2. Las tablas que se exportan
    tablas = Array("DimCliente", "DimProducto", "DimSucursal", _
                   "DimCalendario", "FactRentabilidadMensual", "FactTransacciones")

    ' 3. Actualiza todas las consultas y espera a que terminen
    ThisWorkbook.RefreshAll
    Application.CalculateUntilAsyncQueriesDone

    Application.ScreenUpdating = False
    Application.DisplayAlerts = False

    ' 4. Por cada tabla: copiar a un libro nuevo, dar formato a fechas y guardar como CSV
    For Each nombre In tablas
        Set lo = BuscarTabla(CStr(nombre))
        If lo Is Nothing Then
            Application.DisplayAlerts = True
            Application.ScreenUpdating = True
            MsgBox "No encontré la tabla " & nombre, vbExclamation
            Exit Sub
        End If

        Set libroNuevo = Workbooks.Add(xlWBATWorksheet)
        lo.Range.Copy
        libroNuevo.Sheets(1).Range("A1").PasteSpecial xlPasteValuesAndNumberFormats

        ' Fechas en formato aaaa-mm-dd, que SQL Server entiende sin confusión
        For Each col In libroNuevo.Sheets(1).UsedRange.Columns
            If IsDate(col.Cells(2, 1).Value) Then col.NumberFormat = "yyyy-mm-dd"
        Next col

        libroNuevo.SaveAs carpeta & nombre & ".csv", xlCSVUTF8
        libroNuevo.Close SaveChanges:=False
    Next nombre

    Application.CutCopyMode = False
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True
    MsgBox "Listo: 6 tablas exportadas a " & carpeta, vbInformation
End Sub

' Busca una tabla por su nombre en todas las hojas del libro
Function BuscarTabla(nombre As String) As ListObject
    Dim ws As Worksheet
    On Error Resume Next
    For Each ws In ThisWorkbook.Worksheets
        Set BuscarTabla = ws.ListObjects(nombre)
        If Not BuscarTabla Is Nothing Then Exit Function
    Next ws
End Function
