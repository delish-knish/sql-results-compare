CREATE TABLE [dbo].[QueryComparisonCategory] (
    [QueryComparisonCategoryId]          INT           IDENTITY (1, 1) NOT NULL,
    [EnabledInd]                         BIT           CONSTRAINT [DF_QueryComparisonCategory_EnabledInd] DEFAULT ((1)) NOT NULL,
    [QueryComparisonCategoryName]        VARCHAR (50)  NOT NULL,
    [QueryComparisonCategoryDescription] VARCHAR (255) NOT NULL,
    [CreatedDate]                        DATETIME2 (7) CONSTRAINT [DF_QueryComparisonCategory_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedUser]                        VARCHAR (100) CONSTRAINT [DF_QueryComparisonCategory_CreatedUser] DEFAULT (suser_sname()) NOT NULL,
    [LastUpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_QueryComparisonCategory_LastUpdatedDate] DEFAULT (getdate()) NOT NULL,
    [LastUpdatedUser]                    VARCHAR (100) CONSTRAINT [DF_QueryComparisonCategory_LastUpdatedUser] DEFAULT (suser_sname()) NOT NULL,
    CONSTRAINT [PK_QueryComparisonCategory] PRIMARY KEY CLUSTERED ([QueryComparisonCategoryId] ASC)
);

