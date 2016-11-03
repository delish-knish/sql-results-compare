CREATE TABLE [dbo].[RemoteServer] (
    [RemoteServerId]          INT             IDENTITY (1, 1) NOT NULL,
    [RemoteServerName]        VARCHAR (250)   NOT NULL,
    [RemoteServerDescription] VARCHAR (250)   CONSTRAINT [DF_RemoteServeremoteServerDescription] DEFAULT ('No description given.') NOT NULL,
    [IsMSSQLServerInd]        BIT             CONSTRAINT [DF_RemoteServer_IsMSSQLServerInd] DEFAULT ((0)) NOT NULL,
    [ProviderName]            NVARCHAR (128)  NOT NULL,
    [DataSource]              NVARCHAR (4000) NOT NULL,
    [ProviderString]          NVARCHAR (4000) NULL,
    [Username]                NVARCHAR (100)  NULL,
    [Password]                NVARCHAR (100)  NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_RemoteServer_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedUser]             VARCHAR (100)   CONSTRAINT [DF_RemoteServer_CreatedUser] DEFAULT (suser_sname()) NOT NULL,
    [LastUpdatedDate]         DATETIME2 (7)   CONSTRAINT [DF_RemoteServer_LastUpdatedDate] DEFAULT (getdate()) NOT NULL,
    [LastUpdatedUser]         VARCHAR (100)   CONSTRAINT [DF_RemoteServer_LastUpdatedUser] DEFAULT (suser_sname()) NOT NULL,
    CONSTRAINT [PK_RemoteServer] PRIMARY KEY CLUSTERED ([RemoteServerId] ASC),
    CONSTRAINT [UK_RemoteServer_RemoteServerName] UNIQUE NONCLUSTERED ([RemoteServerName] ASC)
);

