--1.CHECK kısıtlaması
CREATE TABLE Urunler (
    UrunID INT PRIMARY KEY,
    StokAdedi INT CHECK (StokAdedi >= 0)
);

--2.UNIQUE kısıtlaması
CREATE TABLE Kullanici (
    KullaniciID INT PRIMARY KEY,
    Email VARCHAR(100) UNIQUE
);

--3.DEFAULT kısıtlaması
CREATE TABLE Siparisler (
    SiparisID INT PRIMARY KEY,
    SiparisTarihi DATE DEFAULT CAST(GETDATE() AS DATE)
);

--4.Birden fazla kısıtlama
CREATE TABLE Personel (
    PersonelID INT PRIMARY KEY,
    Maas DECIMAL(10, 2) CHECK (Maas >= 10000),
    Email VARCHAR(150) UNIQUE,
    BaslangicTarihi DATE DEFAULT CAST(GETDATE() AS DATE)
);

--5.CHECK belirli değerler arasında
CREATE TABLE Ogrenciler (
    OgrenciID INT PRIMARY KEY,
    NotOrtalamasi DECIMAL(4,2) CHECK (NotOrtalamasi BETWEEN 0 AND 100)
);

--6.UNIQUE Çoklu UNIQUE
CREATE TABLE Kayitlar (
    Ad VARCHAR(50),
    Soyad VARCHAR(50),
    UNIQUE (Ad, Soyad)
);

--7.DEFAULT Boolean benzeri
CREATE TABLE Uyeler (
    UyeID INT PRIMARY KEY,
    AktifMi BIT DEFAULT 1
);

--8.CHECK Cinsiyet kontrolü
CREATE TABLE Kisi (
    ID INT PRIMARY KEY,
    Cinsiyet CHAR(1) CHECK (Cinsiyet IN ('E', 'K'))
);

--9.ALTER TABLE ile CHECK ekleme
ALTER TABLE Urunler
ADD CONSTRAINT chk_Fiyat CHECK (Fiyat > 0);

--10.DEFAULT Kısıtlaması
CREATE TABLE Sipariş (
    SiparişID INT PRIMARY KEY,
    ÜrünID INT,
    Miktar INT DEFAULT 1
);

--Ürün stok adedini kontrol eden
CREATE PROCEDURE CheckProductStock
    @ProductID INT
AS
BEGIN
    DECLARE @Stock INT;

    SELECT @Stock = Stock FROM Products WHERE ProductID = @ProductID;

    IF @Stock IS NULL
        PRINT 'Ürün bulunamadı.';
    ELSE
        PRINT 'Stok miktarı: ' + CAST(@Stock AS VARCHAR);
END;

--Ürün satıldıktan sonra stok miktarını azaltan
CREATE PROCEDURE ReduceProductStock
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    DECLARE @CurrentStock INT;

    SELECT @CurrentStock = Stock FROM Products WHERE ProductID = @ProductID;

    IF @CurrentStock IS NULL
        THROW 50001, 'Ürün bulunamadı.', 1;
    ELSE IF @CurrentStock < @Quantity
        THROW 50002, 'Yeterli stok yok.', 1;
    ELSE
    BEGIN
        UPDATE Products
        SET Stock = Stock - @Quantity
        WHERE ProductID = @ProductID;
    END
END;

--Sipariş oluşturulduysa notification bilgisini çıkaran
CREATE PROCEDURE CreateOrderWithNotification
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Stok kontrol ve azaltma
        EXEC ReduceProductStock @ProductID, @Quantity;

        -- Sipariş oluştur
        INSERT INTO Orders (ProductID, Quantity)
        VALUES (@ProductID, @Quantity);

        -- Bildirim oluştur
        DECLARE @ProductName VARCHAR(100);
        SELECT @ProductName = ProductName FROM Products WHERE ProductID = @ProductID;

        INSERT INTO Notifications (Message)
        VALUES ('Yeni sipariş oluşturuldu: ' + @ProductName + ', Adet: ' + CAST(@Quantity AS VARCHAR));

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
