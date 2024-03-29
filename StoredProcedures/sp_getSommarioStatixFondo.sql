USE [BANZIGO_UTENTI]
GO
/****** Object:  StoredProcedure [dbo].[sp_getSommarioStatixFondo]    Script Date: 05/21/2013 12:06:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_getSommarioStatixFondo]
	@IDFondo int,
	@DATA_DA varchar(10)= NULL,
	@DATA_A varchar(10) = NULL
AS
BEGIN
	
	
	Select * INTO #TempTable  FROM [dbo].[fn_getStatixFondo](@IDFondo )
	
	SELECT DSC_TIPO_ELABORAZIONE,ID_ELABORAZIONE, LCF.DTA_GENERAZIONE,
	DTA_INIZIO_ELABORAZIONE,DTA_FINE_ELABORAZIONE,NUM_REC_ERRATI,NUM_REC_CORRETTI, 
	
	isnull(
			(
				SELECT SUM(NumerositaStato) 
				FROM #TempTable  gSS
				GROUP BY DESC_STATO_RECORD
				HAVING  DESC_STATO_RECORD=dbo.fn_GetValueDatiGenerici('SRC','CTR' )
			),0) CONTROLLATI,
		
	isnull(
			(
				SELECT SUM(NumerositaStato) 
				FROM #TempTable  gSS
				GROUP BY DESC_STATO_RECORD
				HAVING DESC_STATO_RECORD=dbo.fn_GetValueDatiGenerici('SRC','INS' )
			),0) INSERITI,
			
	Isnull(
			(
				SELECT SUM(NumerositaStato) 
				FROM #TempTable  gSS
				GROUP BY DESC_STATO_RECORD
				HAVING DESC_STATO_RECORD=dbo.fn_GetValueDatiGenerici('SRC','CAL' )
			),0) CALCOLATI,
	
	Isnull(
			(
				SELECT SUM(NumerositaStato) 
				FROM #TempTable  gSS
				GROUP BY DESC_STATO_RECORD
				HAVING DESC_STATO_RECORD=dbo.fn_GetValueDatiGenerici('SRC','CNF' )
			),0) CONFERMATI,
	
	Isnull(
			(
				SELECT SUM(NumerositaStato) 
				FROM #TempTable  gSS
				GROUP BY DESC_STATO_RECORD
				HAVING DESC_STATO_RECORD=dbo.fn_GetValueDatiGenerici('SRC','LAV' )
			),0) LAVORATI,

	Isnull(
			(
				SELECT SUM(NumerositaStato) 
				FROM #TempTable  gSS
				GROUP BY DESC_STATO_RECORD
				HAVING DESC_STATO_RECORD=dbo.fn_GetValueDatiGenerici('SRC','AVV' )
			),0) AVVALORATI,

	Isnull(
			(
				SELECT SUM(NumerositaStato) 
				FROM #TempTable  gSS
				GROUP BY DESC_STATO_RECORD
				HAVING DESC_STATO_RECORD=dbo.fn_GetValueDatiGenerici('SRC','ANN' )
			),0) ANNULLATI,

	(SELECT Sum(StatiErrore) 
		FROM #TempTable  gSS
		group by StatiErrore
		 ) Errori,

	(SELECT Sum(StatiBlocco) 
		FROM #TempTable  gSS
		group by StatiBlocco ) Blocchi

	FROM STS_LOG_ELABORAZIONI LE 
		inner join STS_LOG_CARICAMENTI_FLUSSI LCF on LCF.ID_FILE=LE.ID_FILE
		inner join STS_MST_TIPI_ELABORAZIONI TEL on TEL.ID_TIPO_ELABORAZIONE=LE.ID_TIPO_ELABORAZIONE
		WHERE LE.ID_FILE in(Select ID_FILE  FROM #TempTable )
		and ID_ELABORAZIONE =(
			SELECT max(id_elaborazione)
			from STS_LOG_ELABORAZIONI LE
				inner join STS_LOG_CARICAMENTI_FLUSSI LCF on LCF.ID_FILE=LE.ID_FILE
			WHERE LE.ID_FILE in(Select ID_FILE  FROM #TempTable )
			)

	AND (DTA_GENERAZIONE >= CONVERT(DATETIME,@DATA_DA,103) OR (@DATA_DA = '' OR @DATA_DA IS NULL)) 
	AND (DTA_GENERAZIONE <= CONVERT(DATETIME,@DATA_A,103) OR (@DATA_A = '' OR @DATA_A IS NULL))	
	
END

