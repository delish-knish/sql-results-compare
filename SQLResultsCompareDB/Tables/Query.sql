CREATE TABLE [dbo].[Query] (
    [QueryId]          INT            IDENTITY (1, 1) NOT NULL,
    [RemoteServerId]   INT            NOT NULL,
    [QueryName]        NVARCHAR (50)  NOT NULL,
    [QueryDescription] NVARCHAR (255) NOT NULL,
    [Query]            NVARCHAR (MAX) NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [DF_Query_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedUser]      NVARCHAR (100) CONSTRAINT [DF_Query_CreatedUser] DEFAULT (suser_sname()) NOT NULL,
    [LastUpdatedDate]  DATETIME2 (7)  CONSTRAINT [DF_Query_LastUpdatedDate] DEFAULT (getdate()) NOT NULL,
    [LastUpdatedUser]  NVARCHAR (100) CONSTRAINT [DF_Query_LastUpdatedUser] DEFAULT (suser_sname()) NOT NULL,
    CONSTRAINT [PK_Query] PRIMARY KEY CLUSTERED ([QueryId] ASC),
    CONSTRAINT [FK_Query_RemoteServer] FOREIGN KEY ([RemoteServerId]) REFERENCES [dbo].[RemoteServer] ([RemoteServerId])
);

