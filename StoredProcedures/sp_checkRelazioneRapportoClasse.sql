USE [BANZIGO_UTENTI]
GO
/****** Object:  StoredProcedure [dbo].[sp_checkRelazioneRapportoClasse]    Script Date: 05/21/2013 12:05:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:		Pierpaolo Francocci
-- Create date: Settembre 2010
-- Description:	Controlla l'esistenza della relazione rapporto e classe di quota
-- =============================================
ALTER PROCEDURE  [dbo].[sp_checkRelazioneRapportoClasse]	
	@ID_FILE int,
	@ID_RECORD int=NULL
AS
BEGIN
	DECLARE @CheckRel CURSOR
	DECLARE @TXT_PROGR_MOVIMENTO varchar(9)
	DECLARE @COD_CAUSALE varchar(9)
	

	DECLARE @ID_RAPPORTO int
	DECLARE @ID_CLASSE_QUOTA int 
	DECLARE @ID_FONDO int
	DECLARE @COD_FONDO varchar(2)
	DECLARE @RelazioneRapportoClasse varchar(20)

	DECLARE @Controllox100 VARCHAR(100)
	DECLARE @ID_REC INT
	
	DECLARE @debug bit
	

	declare @IdStatoOut SQL_VARIANT
	EXEC sp_GetGlobalVariableValue 'g_Debug' ,@IdStatoOut output 
	SET @debug=CAST(@IdStatoOut AS BIT)
			
	IF @debug =1
	BEGIN
		PRINT 'sp_checkRelazioneRapportoClasse' 
		PRINT '@ID_FILE '+CAST(@ID_FILE  AS VARCHAR(20))
		PRINT '@ID_RECORD '+CAST(@ID_RECORD AS VARCHAR(20))
	END
	

	SET @CheckRel= CURSOR FOR
		select distinct TXT_PROGR_MOVIMENTO,ID_FILE, TXT_COD_CAUSALE, ID_RECORD 
		from STS_STA_TR100
		WHERE  CAST(TXT_COD_RAPPORTO AS int) <>0
			AND ID_FILE =@ID_FILE
--prende in considerazione solo quelli per cui esistono dei record correlati 
			--AND CONVERT(VARCHAR(20),ID_FILE)+TXT_PROGR_MOVIMENTO    in 
			--	(select distinct CONVERT(VARCHAR(20),ID_FILE)+TXT_PROGR_MOVIMENTO  from STS_STA_TR20X_TR300	)		
			AND (ID_RECORD =@ID_RECORD OR @ID_RECORD IS NULL)

	OPEN @CheckRel
	FETCH NEXT
	FROM @CheckRel INTO @TXT_PROGR_MOVIMENTO, @ID_FILE, @COD_CAUSALE, @ID_REC  
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT @TXT_PROGR_MOVIMENTO IS null
		BEGIN
			SELECT @Controllox100 =ISNULL(Controllox100 , '') 
			FROM dbo.fn_getDaticonErrori_IdRec(@ID_REC  )
			WHERE TXT_TIPO_RECORD='100'

			IF NOT @Controllox100 ='ERRORE'--@COD_CAUSALE='RI'
			BEGIN
				
				SET @ID_RAPPORTO=dbo.fn_GetRapporto(@TXT_PROGR_MOVIMENTO,@ID_FILE,NULL)
				IF @debug =1
					PRINT '@ID_RAPPORTO '+ CAST(@ID_RAPPORTO AS VARCHAR(50))
				IF @ID_RAPPORTO=0
					IF @debug =1
						PRINT '@TXT_PROGR_MOVIMENTO x @ID_RAPPORTO a zero -->'+@TXT_PROGR_MOVIMENTO
				SELECT TOP 1 @ID_CLASSE_QUOTA=IdClasseQuota,@ID_FONDO = IdFondo, @COD_FONDO=CodFondo
					FROM dbo.fn_GetFondiClassiQuote(@TXT_PROGR_MOVIMENTO,@ID_FILE)

				SET @RelazioneRapportoClasse=(
						CASE 
							WHEN dbo.fn_EsisteRelRapportoClasse(@ID_RAPPORTO,@ID_CLASSE_QUOTA)=1 
								THEN 'ESISTE'
								ELSE 'NON ESISTE'
						END)
				
				IF @debug =1
					PRINT '@RelazioneRapportoClasse '+@RelazioneRapportoClasse
				if @RelazioneRapportoClasse ='NON ESISTE'
				BEGIN	
					IF @debug =1
						SELECT @TXT_PROGR_MOVIMENTO, @ID_FILE ,@ID_RAPPORTO,@ID_CLASSE_QUOTA,@ID_FONDO ,@COD_FONDO, @RelazioneRapportoClasse

					INSERT STS_REL_RAPPORTI_CLASSI
					(
						ID_RAPPORTO,
						ID_CLASSE_QUOTA
					)
					VALUES
					(
						@ID_RAPPORTO,
						@ID_CLASSE_QUOTA
					)	
				END
				ELSE
				BEGIN
					PRINT @TXT_PROGR_MOVIMENTO+' '+convert(varchar(10), @ID_FILE )+' '+
					convert(varchar(10), @ID_RAPPORTO)+' '+convert(varchar(10), @ID_CLASSE_QUOTA)+' '+
					convert(varchar(10), @ID_FONDO )+' '+convert(varchar(10), @COD_FONDO )+' '+@RelazioneRapportoClasse
				END
				
				IF @debug =1
				BEGIN
					PRINT '@ID_RAPPORTO ' +CAST(@ID_RAPPORTO AS VARCHAR(20))
					PRINT '@ID_CLASSE_QUOTA ' +CAST(@ID_CLASSE_QUOTA AS VARCHAR(20))					
				END	
				
				
				UPDATE STS_STA_TR100
				SET ID_RAPPORTO_CLASSE=
					(
					SELECT ID_RAPPORTO_CLASSE 
						FROM STS_REL_RAPPORTI_CLASSI
						WHERE ID_RAPPORTO=@ID_RAPPORTO 
						AND ID_CLASSE_QUOTA=@ID_CLASSE_QUOTA
					)
				WHERE TXT_PROGR_MOVIMENTO=@TXT_PROGR_MOVIMENTO
				AND ID_FILE =@ID_FILE 
				AND (ID_RECORD =@ID_RECORD OR @ID_RECORD IS NULL)
				
				IF @debug =1
				begin
					PRINT 'controllo x ID_RAPPORTO_CLASSE su STS_STA_TR100'
					SELECT ID_RAPPORTO_CLASSE
					FROM STS_STA_TR100
					WHERE TXT_PROGR_MOVIMENTO=@TXT_PROGR_MOVIMENTO
					AND ID_FILE =@ID_FILE 
					AND (ID_RECORD =@ID_RECORD OR @ID_RECORD IS NULL)
				end
			END
		end
		FETCH NEXT
		FROM @CheckRel INTO @TXT_PROGR_MOVIMENTO, @ID_FILE, @COD_CAUSALE, @ID_REC 
	END
	CLOSE @CheckRel
	DEALLOCATE @CheckRel

END








