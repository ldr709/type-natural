{-# LANGUAGE DataKinds, EmptyDataDecls, FlexibleContexts, FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs, KindSignatures, PolyKinds, StandaloneDeriving           #-}
{-# LANGUAGE TypeFamilies, TypeOperators                                    #-}
-- | Set-theoretic ordinal arithmetic
module Data.Type.Ordinal
       ( -- * Data-types
         Ordinal (..),
         -- * Conversion from cardinals to ordinals.
         sNatToOrd', sNatToOrd, ordToInt, ordToSNat,
         -- * Ordinal arithmetics
         (@+)
       ) where
import Data.Type.Monomorphic
import Data.Type.Natural

-- | Set-theoretic (finite) ordinals:
--
-- > n = {0, 1, ..., n-1}
--
-- So, @Ordinal n@ has exactly n inhabitants. So especially @Ordinal Z@ is isomorphic to @Void@.
data Ordinal n where
  OZ :: Ordinal (S n)
  OS :: Ordinal n -> Ordinal (S n)

-- | Parsing always fails, because there are no inhabitant.
instance Read (Ordinal Z) where
  readsPrec _ _ = []

deriving instance Read (Ordinal n) => Read (Ordinal (S n))
deriving instance Show (Ordinal n)
deriving instance Eq (Ordinal n)
deriving instance Ord (Ordinal n)

-- | 'sNatToOrd'' @n m@ injects @m@ as @Ordinal n@.
sNatToOrd' :: (S m :<<= n) ~ True => SNat n -> SNat m -> Ordinal n
sNatToOrd' (SS _) SZ = OZ
sNatToOrd' (SS n) (SS m) = OS $ sNatToOrd' n m
sNatToOrd' _ _ = bugInGHC

-- | 'sNatToOrd'' with @n@ inferred.
sNatToOrd :: (SingRep n, (S m :<<= n) ~ True) => SNat m -> Ordinal n
sNatToOrd = sNatToOrd' sing

-- | Convert @Ordinal n@ into monomorphic @SNat@
ordToSNat :: Ordinal n -> Monomorphic (Sing :: Nat -> *)
ordToSNat OZ = Monomorphic SZ
ordToSNat (OS n) =
  case ordToSNat n of
    Monomorphic sn ->
      case singInstance sn of
        SingInstance -> Monomorphic (SS sn)

-- | Convert ordinal into @Int@.
ordToInt :: Ordinal n -> Int
ordToInt OZ = 0
ordToInt (OS n) = 1 + ordToInt n

-- | Inclusion function for ordinals.
inclusion' :: (n :<<= m) ~ True => SNat m -> Ordinal n -> Ordinal m
inclusion' (SS SZ) OZ = OZ
inclusion' (SS (SS _)) OZ = OZ
inclusion' (SS (SS n)) (OS m) = OS $ inclusion' (sS n) m
inclusion' _ _ = bugInGHC

-- | Inclusion function for ordinals with codomain inferred.
inclusion :: ((n :<<= m) ~ True, SingRep m) => Ordinal n -> Ordinal m
inclusion = inclusion' sing

-- | Ordinal addition.
(@+) :: forall n m. (SingRep n, SingRep m) => Ordinal n -> Ordinal m -> Ordinal (n :+ m)
OZ @+ n =
  let sn = sing :: SNat n
      sm = sing :: SNat m
  in case singInstance (sn %+ sm) of
       SingInstance ->
         case propToBoolLeq (plusLeqR sn sm) of
           LeqTrueInstance -> inclusion n
OS n @+ m =
  case sing :: SNat n of
    SS sn -> case singInstance sn of SingInstance -> OS $ n @+ m
    _ -> bugInGHC
