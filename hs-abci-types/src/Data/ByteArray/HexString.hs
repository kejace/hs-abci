{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}

module Data.ByteArray.HexString where

import           Data.Aeson              (FromJSON (..), ToJSON (..),
                                          Value (..), withText)
import           Data.ByteArray          (ByteArray, ByteArrayAccess, convert)
import qualified Data.ByteArray          as BA (drop, take)
import           Data.ByteArray.Encoding (Base (Base16), convertFromBase,
                                          convertToBase)
import           Data.ByteString         (ByteString)
import           Data.Monoid             (Monoid, (<>))
import           Data.Semigroup          (Semigroup)
import           Data.String             (IsString (..))
import           Data.Text               (Text)
import           Data.Text.Encoding      (decodeUtf8, encodeUtf8)
import           GHC.Generics            (Generic)

-- | Represents a Hex string. Guarantees that all characters it contains
--   are valid hex characters.
newtype HexString = HexString { unHexString :: ByteString }
  deriving (Eq, Ord, Generic, Semigroup, Monoid, ByteArrayAccess, ByteArray)

instance Show HexString where
    show = ("HexString " ++) . show . format

instance IsString HexString where
    fromString = hexString' . fromString
      where
        hexString' :: ByteString -> HexString
        hexString' = either error id . hexString

instance FromJSON HexString where
    parseJSON Null = pure (fromBytes ("" :: ByteString))
    parseJSON v = withText "HexString" (either fail pure . hexString . encodeUtf8) v

instance ToJSON HexString where
    toJSON = String . toText

-- | Smart constructor which trims '0x' and validates length is even.
--   Works with any mixed casing of characters:
--   `hexString "0xAA" == hexString "0xAa" == hexString "0xaA" == hexString "0xaa"`
hexString :: ByteArray ba => ba -> Either String HexString
hexString bs = HexString <$> convertFromBase Base16 bs'
  where
    hexStart = convert ("0x" :: ByteString)
    bs' | BA.take 2 bs == hexStart = BA.drop 2 bs
        | otherwise = bs

-- | Reads a raw bytes and converts to hex representation.
fromBytes :: ByteArrayAccess ba => ba -> HexString
fromBytes = HexString . convert

-- | Access to the raw bytes of 'HexString'.
toBytes :: ByteArray ba => HexString -> ba
toBytes = convert . unHexString

-- | Access to a 'Text' representation of the 'HexString'
toText :: HexString -> Text
toText = decodeUtf8 . convertToBase Base16 . unHexString

-- | Access to a 'Text' representation of the 'HexString'
format :: HexString -> Text
format a = "0x" <> toText a
