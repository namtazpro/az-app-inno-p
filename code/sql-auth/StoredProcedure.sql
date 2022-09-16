/****** Object:  StoredProcedure [dbo].[GetProducts]    Script Date: 16/09/2022 18:30:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: <Description, , >
-- =============================================
CREATE PROCEDURE [dbo].[GetProducts]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT [productid]
		  ,[productname]
		  ,[productdesc]
		  ,[publicprice]
		  ,[internalcost]
		  ,[date]
	  FROM [dbo].[Products]

END
GO


