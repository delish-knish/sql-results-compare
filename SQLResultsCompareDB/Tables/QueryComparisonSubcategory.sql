CREATE TABLE [dbo].[QueryComparisonSubcategory] (
    [QueryComparisonSubcategoryId]          INT           NOT NULL,
    [EnabledInd]                            BIT           CONSTRAINT [DF_QueryComparisonSubcategory_EnabledInd] DEFAULT ((1)) NOT NULL,
    [QueryComparisonSubcategoryName]        VARCHAR (50)  NOT NULL,
    [QueryComparisonSubcategoryDescription] VARCHAR (255) NOT NULL,
    [QueryComparisonCategoryId]             INT           NOT NULL,
    [CreatedDate]                           DATETIME2 (7) CONSTRAINT [DF_QueryComparisonSubcategory_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedUser]                           VARCHAR (100) CONSTRAINT [DF_QueryComparisonSubcategory_CreatedUser] DEFAULT (suser_sname()) NOT NULL,
    [LastUpdatedDate]                       DATETIME2 (7) CONSTRAINT [DF_QueryComparisonSubcategory_LastUpdatedDate] DEFAULT (getdate()) NOT NULL,
    [LastUpdatedUser]                       VARCHAR (100) CONSTRAINT [DF_QueryComparisonSubcategory_LastUpdatedUser] DEFAULT (suser_sname()) NOT NULL,
    CONSTRAINT [PK_QueryComparisonSubcategory] PRIMARY KEY CLUSTERED ([QueryComparisonSubcategoryId] ASC),
    CONSTRAINT [FK_QueryComparisonSubcategory_QueryComparisonCategory] FOREIGN KEY ([QueryComparisonCategoryId]) REFERENCES [dbo].[QueryComparisonCategory] ([QueryComparisonCategoryId])
);

