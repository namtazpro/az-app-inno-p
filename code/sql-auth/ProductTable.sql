/****** Object:  Table [dbo].[Products]    Script Date: 16/09/2022 18:23:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Products](
	[productid] [int] IDENTITY(1,1) NOT NULL,
	[productname] [varchar](50) NOT NULL,
	[productdesc] [varchar](50) NOT NULL,
	[publicprice] [numeric](18, 2) NOT NULL,
	[internalcost] [numeric](18, 2) NOT NULL,
	[date] [datetime] NOT NULL,
 CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED 
(
	[productid] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_date]  DEFAULT (getdate()) FOR [date]
GO


