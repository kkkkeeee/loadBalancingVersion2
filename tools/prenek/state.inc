      PARAMETER (MXSTAT=5)
      PARAMETER (MXIS=50+NELM)
      COMMON /CISTAT/ NSTATE,ISTAT(MXIS,MXSTAT)
      COMMON /CCSTAT/ CSTAT(  40,MXSTAT)
      COMMON /CLSTAT/ LSTAT(  40,MXSTAT),ifstate
      COMMON /CRSTAT/ RSTAT( 100,MXSTAT)
      LOGICAL LSTAT
      CHARACTER*20 CSTAT
      LOGICAL ifstate