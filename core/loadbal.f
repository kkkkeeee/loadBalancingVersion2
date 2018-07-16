      subroutine assign_partitions !(gllnid, lelt, nelgt, np)
c     This subroutine is used for update gllnid            
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL' !these include contains gllnid, lelt, and np     

      !integer gllnid(1) !, lelt, nelgt, np
      common /elementload/ gfirst, inoassignd, resetFindpts, pload(lelg)
      integer gfirst, inoassignd, resetFindpts
      integer pload
      integer psum(lelg)
      integer nw, k, nel, nmod, npp  !the number of particles
c     nw=200 
      
      call izero(pload, lelg)
c      call randGenet(pload, nelgt, nw) !random assign pload
c     call preSum(pload, psum, nelgt) !calculate the prefix sum of pload
c      call ldblce(psum, nelgt, gllnid, np) !equally distribute the load to np processor, assigned to gllnid
      
c     uniformally assign element
      nel = nelgt/np
      nmod  = mod(nelgt,np)  ! bounded between 1 ... np-1
      npp   = np - nmod      ! how many paritions of size nel
      ! setup partitions of size nel
      k   = 0
      do ip = 0,npp-1
         do e = 1,nel
            k = k + 1
            gllnid(k) = ip
         enddo
      enddo
      ! setup partitions of size nel+1
      if(nmod.gt.0) then
        do ip = npp,np-1
           do e = 1,nel+1
              k = k + 1
              gllnid(k) = ip
           enddo
        enddo
      endif

c     part = nelgt/np
c     do i=1, nelgt
c        gllnid(i) = (i-1)/part
c     enddo
c      call printi(gllnid, nelgt)

      end subroutine

c----------------------------------------------------------------

c This subroutine assign normalized random number to pload of length len; and make the sum of pload equal to total, pload store the actual number of particles in elements
      subroutine randGenet(pload, len, total)
      integer len, total
      integer pload(len)
c     local variable
      real temppload(len)
      integer i, seed, summ2
      real summ, summ1
c     real mu, sigma, r4_normal_ab

      summ=0
      summ1=0
      summ2=0
      !call RANDOM_NUMBER(pload)   !random generate len values and store in pload
      seed = 123456789
      mu = 20.0e+01
      sigma = 170.0e+00

      do i=1, len
c        r4_normal_ab introduced new file normal.f
c        temppload(i) = r4_normal_ab (mu, sigma, seed) !generate normalize number
          if (temppload(i) .lt. 0) then
             temppload(i) = 0
          endif
      enddo
      !print *, 'temppload:'
      !call printr(temppload, len)

      do 10 i=1, len
         summ=summ+temppload(i)
   10 continue

      !print *, 'The sum of pload is: ', summ 
      do 20 i=1, len
        temppload(i)=temppload(i)*total/summ  !make the total of pload equal to total
        summ1=summ1+temppload(i)
   20 continue
      !print *, 'The new sum of pload is: ', summ1

      !print *, 'temppload:'
      !call printr(temppload, len)     

      do i = 1, len-1
         pload(i) = int(temppload(i))! convert real to int, cut off
         summ2 = summ2 + pload(i)
      enddo
      if ( total .le. summ2) then
         pload(len) = 0
      else
         pload(len) = total - summ2
      endif

      return
      end

c------------------------------------------------------------------

c     subroutine to get prefix sum
      subroutine preSum(pload, psum, len)
      integer pload(len)
      integer psum(len)
      integer i
      psum(1)=pload(1)
      do 30 i=2, len
          psum(i)=psum(i-1)+pload(i)
  30  continue

      return
      end


c     subroutine to get prefix sum for real
      subroutine preSumr(pload, psum, len)
      real pload(len)
      real psum(len)
      integer i
      psum(1)=pload(1)
      do 30 i=2, len
          psum(i)=psum(i-1)+pload(i)
  30  continue

      return
      end
c--------------------------------------------------------
      subroutine computeRatio
      include 'mpif.h'
      include 'SIZE'
      include 'CMTTIMERS'
      include 'TSTEP'
      include 'PARALLEL'
      include 'CMTPART'
      common /nekmpi/ mid,mp,nekcomm,nekgroup,nekreal
      integer status_mpi(MPI_STATUS_SIZE)
      common /elementload/ gfirst, inoassignd, resetFindpts, pload(lelg)
      integer gfirst, inoassignd, resetFindpts, pload
      common /f2pratio/ ratio
      integer reinit_step2
      save reinit_step2
      data reinit_step2 /0/
      real ratio
      real r1, r2, pmax, fmax

c        rdumt  = ftime/(istep-reinit_step2)
c        rdumi  = pttime(1)/(istep-reinit_step2)
c        rdump  = pttime(5)/(istep-reinit_step2)
c        pmax = glmax(rdump, 1) !added by keke
c        pmin = glmin(rdump, 1)
c        fmax = glmax(rdumt-rdumi-rdump, 1)
c        fmin = glmin(rdumt-rdumi-rdump, 1)
c        maxpar = maxpar/(istep-reinit_step2)
c        maxnelt = maxnelt/(istep-reinit_step2)
c        r1 = fmax/maxnelt*ceiling(nelgt*1.0/np)*ceiling(nw*1.0/nelgt)
c        r2 = pmax/maxpar*(ceiling(nelgt*1.0/np)-1)
c        ratio = sqrt(r1/r2)/ceiling(nw*1.0/nelgt)
c        minpar = iglmin(n, 1)
c        minnelt = iglmin(nelt, 1) 

c        if(nio.eq.0)
c    >      write(6,*) istep,fmax, maxnelt, pmax, maxpar,fmin, pmin,
c    >                  minnelt, minpar, ratio,
c    >                 'ratio                       '
c        ftime = 0
c        pttime(1) = 0
c        pttime(5) = 0
c        maxpar = 0
c        maxnelt = 0
c        reinit_step2 = istep

         !ratio = 0.5 or 1.0 for overhead
         !ratio = 0.2 for highPerformanceExperiment   
         ratio = 1.0 !1.0 !0.5 !0.2 


      return 
      end
c--------------------------------------------------------
c     assign to corresponding processor, limit the number of element
c     assigned to each processor
      subroutine ldblce_limit(psum, len, gllnid, np)
         include "SIZE"
         integer psum(len)
         integer np
         integer gllnid(len)

         integer i,j, k, flag, ne
         integer pos(np+1)  !pos(i)-pos(i+1)-1 belong to processor i-1
         real diff, diffn, thresh
         i=1
         flag = 0
         thresh=psum(len)*1.0/np*i
         if(nid .eq.0) print *, 'thresh', thresh
     >     ,psum(28), psum(29), psum(30) 
         call izero(pos, np+1)
         pos(1)=1
         ne = 0
         do 70 j=2, len
            diff=abs(thresh-psum(j-1))
            diffn=abs(thresh-psum(j))
            if(diff .ge. diffn) then
               !write(*,*) "i:", i, "pos(i):", pos(i)
               ! bring in lelt
               ne=ne+1 
               if (ne > lelt-1) then
                   print *,i, "Number of elements",
     $              "exceeds lelt = ", lelt
                   pos(i+1)=j
                   ne = 0
                   i = i + 1
                   thresh=psum(len)*1.0/np*i
                   !thresh = psum(j) + psum(len)*1.0/np  
               else 
                   pos(i+1)=j+1
               endif
            else
               pos(i+1)=j
               !write(*,*) "i/:", i, "pos(i):", pos(i)
               i=i+1
               thresh=psum(len)*1.0/np*i
               !thresh = psum(j) + psum(len)*1.0/np  
               ne = 0
            endif
  70      continue
c         print *, 'prefix sum, len: ', len
c         call printi(psum, len)
c         print *, ' i', i
          !call printi(pos, np+1)
          if( i .lt. np) then ! this part is for the partition less than np
              do k = i+2, np+1
                 pos(k) = len + 1
              enddo
          endif 
c         print *, 'printing pos'
c         call printi(pos, np+1)
c         do i=1, np+1  !verify loadbal
c            print *,'pos:', i, pos(i)
c         enddo 

c         print *, 'load of p', 0, psum(pos(2)-1)
c    $                 ,pos(1), pos(1+1)-1    
          do 80 i=1, np
c            print *, 'load of p', i-1, psum(pos(i+1)-1)-psum(pos(i)-1)
c    $                 ,pos(i), pos(i+1)-1    
             do 90 j=pos(i), pos(i+1)-1
                gllnid(j)=i-1
  90         continue
  80      continue
c         print *, 'printing gllnid, length: ',len 
c         call printi(gllnid, len)
          
      return
      end


c--------------------------------------------------------
c     assign to corresponding processor, limit the number of element
c     assigned to each processor
      subroutine ldblce_limit_real(psum, len, gllnid, np)
         include "SIZE"
         real psum(len)
         integer np
         integer gllnid(len)

         integer i,j, k, flag, ne
         integer pos(np+1)  !pos(i)-pos(i+1)-1 belong to processor i-1
         real diff, diffn, thresh
         i=1
         flag = 0
         thresh=psum(len)*1.0/np*i
         if(nid .eq.0) print *, 'thresh', thresh
c    >     ,psum(28), psum(29), psum(30) 
         call izero(pos, np+1)
         pos(1)=1
         ne = 0
         do j=2, len
            diff=abs(thresh-psum(j-1))
            diffn=abs(thresh-psum(j))
            if(diff .ge. diffn) then
               ne=ne+1 
               if (ne > lelt-1) then
                   print *,i, "Number of elements",
     $              "exceeds lelt = ", lelt
                   pos(i+1)=j
                   ne = 0
                   i = i + 1
                   !thresh=psum(len)*1.0/np*i
                   thresh=(psum(len)-psum(j-1))*1.0/(np-i+1)+psum(j-1)
               else 
                   pos(i+1)=j+1
               endif
            else
               pos(i+1)=j
               i=i+1
               !thresh=psum(len)*1.0/np*i
               thresh=(psum(len)-psum(j-1))*1.0/(np-i+1)+psum(j-1)
               ne = 0
            endif
          enddo

          if( i .lt. np) then ! this part is for the partition less than np
              do k = i+2, np+1
                 pos(k) = len + 1
              enddo
          endif 

          do 80 i=1, np
             do 90 j=pos(i), pos(i+1)-1
                gllnid(j)=i-1
  90         continue
  80      continue
      return
      end

c--------------------------------------------------------
c     assign to corresponding processor of gllnid, distributed method
      subroutine ldblce_hybrid(psum, newgllnid)
      include 'mpif.h'
      include 'SIZE'
      include 'PARALLEL'
      include 'CMTPART'
      include 'TSTEP'

      common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal

      integer psum(nelt), newgllnid(nelgt)
      real ithreshb!, ratio!, threshil, threshh
      integer totalload, diva, ierr, pnelt, m, j
      integer tempgllnid(nelt), preElem
      integer nelt_array_psum(np)
      integer status_mpi(MPI_STATUS_SIZE)
      integer posArray(3, np), npos, nposArray(np), posArrayGlo(2,np)
      integer preSum_npos, npos_array(np), posArrayGlo_2(2,np), indexp
      real starttime1, endtime
      integer mdw, ndw, temp1, temp2
      common /f2pratio/ ratio
      real ratio
!     posArray store where the element change; for example, if
!     tempgllnid={0,0,0,1,1,1,2,3,3}, posArray=
!     (0,1)(1,4)(2,7)(3,8)

      starttime1 = dnekclock_sync()
      !ratio = 1.0
      totalload = nw + ceiling(ratio*ceiling(nw*1.0/nelgt))*nelgt
      !print *, nid_, totalload

      threshb = totalload*1.0/np
      if(nid.eq.0) print *, 'totalload', totalload, 'thresh', threshb
     $     , 'ratio', ratio, 'ldblce_hybrid'

      do i = 1, nelt
         diva = AINT((psum(i)-1)*1.0/threshb)
         tempgllnid(i) = diva
c        write(6, '(A9,5I16)') 'psum_hy', istep, nid, 
c    $    i, psum(i), tempgllnid(i)
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new psum', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     send tempgllnid(nelt) to the next processor, except for the last processor
      if(nid .ne. np-1) then
         call mpi_send(tempgllnid(nelt), 1, mpi_integer, nid+1, 0
     $      , nekcomm, ierr)
c        print *, 'send ', nid, nid+1, tempgllnid(nelt)
      endif

      if(nid .ne. 0) then
         call mpi_recv(preElem, 1, mpi_integer, nid-1, 0, nekcomm
     $      , status_mpi, ierr)
c        print *, 'receive ', nid-1, nid, preElem
      endif
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new send_recv', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

cc     Get exclusive prefix sum of nelt, sort it in pnelt
c      pnelt = igl_running_sum_ex(nelt)
c      endtime = dnekclock_sync()
c      if( mod(nid, np/2) .eq. np/2-2) then
c         print *, 'ldblce_dist_new ex_sum1', endtime-starttime1
c      endif
c      starttime1 = dnekclock_sync()

      call izero(posArray, 3*np)
      npos = 0
      if(nid .eq. 0) preElem = -1
      if(preElem .ne. tempgllnid(1)) then
         npos = npos + 1
         posArray(1,npos) = tempgllnid(1)
         posArray(2,npos) = lglel(1)  !1 + pnelt !get the local element id
         posArray(3,npos) = 0  !send to p0
      endif
      preElem = tempgllnid(1)
      do i=2, nelt
          if(preElem .ne. tempgllnid(i)) then
             npos = npos + 1
             posArray(1,npos) = tempgllnid(i)
             posArray(2,npos) = lglel(i)   !i + pnelt !get the global element id
             posArray(3,npos) = 0  !send to p0
             preElem = tempgllnid(i)
          endif
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new preElem', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()
c     do i=1, npos
c        write(6, '(A6,6I16)') 'npos', istep, nid, i, posArray(1,i)
c    $ , posArray(2,i), posArray(3, i) 
c     enddo
      
      mdw = 3
      ndw = np
      key = 3
      call crystal_ituple_transfer(cr_h, posArray, mdw, npos, ndw, key)
c     print *, "tuple   ***", nid, npos
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new transfer', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

      if(nid .eq. 0) then
         key = 1
         nkey = 1
c        print *, "p0 come here"
         call crystal_ituple_sort(cr_h, posArray, mdw, npos, key, nkey)
         starttime1 = dnekclock() !no sync here
c        do i=1, npos
c           write(6, '(A6,5I16)') 'npos2', istep, nid, i, posArray(1,i)
c    $    , posArray(2,i), posArray(3, i) 
c        enddo

c     copy posArrayGlo to posArrayGlo_2 is to avoid the suitation like
c        follows:
c     posArrayGlo(1,i)  0 2 3 4 5 
c     posArrayGLO(2,i)  1 2 3 4 7
c     that porcessor 1 don't have any load, incurring the error in the
c     limit lelt process.
         call izero(posArrayGlo_2, 2*np)
         if(npos .lt. np) then !there is no above situation   
c          go to 20
c        else 
           posArrayGlo_2(1,1) = posArray(1,1)
           posArrayGlo_2(2,1) = posArray(2,1)
           indexp = 1  
c            if(nid.eq.0) print *, 'posArrayGlo_2', 1,posArrayGlo_2(1,1)
c    $      , posArrayGlo_2(2,1), posArrayGlo(2,1)    
           do i =2, np
             if(posArray(1, indexp+1) .eq. posArrayGlo_2(1,i-1)+1) then
               posArrayGlo_2(1,i) = posArray(1,indexp+1)
               if((posArray(2,indexp+1) .le. posArrayGlo_2(2,i-1)
     $            +lelt).and.(posArray(2,indexp+1)
     $              .gt.posArrayGlo_2(2,i-1))) then
                  posArrayGlo_2(2,i) = posArray(2,indexp+1)
               else if (posArray(2,indexp+1) .gt.
     $            posArrayGlo_2(2,i-1) +lelt) then
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+lelt
               else
                  temp1 = ceiling((posArrayGlo_2(2,i-1) +
     $                   posArray(2,indexp+2))*1.0/2)
                  if(temp>posArrayGlo_2(2,i-1)) then
                    posArrayGlo_2(2,i) = temp
                  else
                    posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1) +1
                  endif
               endif    
              indexp = indexp+1  
             else if(posArray(1,indexp+1).gt.posArrayGlo_2(1,i-1)+1)then
                posArrayGlo_2(1,i) = posArrayGlo_2(1,i-1)+1
                temp2 =ceiling((posArray(2,indexp+1)-
     $             posArrayGlo_2(2,i-1))*1.0/
     $          (posArray(1,indexp+1)-posArrayGlo_2(1,i-1)))
                if(temp2>0) then
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+temp2
                else
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+1
                endif
              endif  
            enddo
          else
            do i = 1, np
               posArrayGlo_2(1,i) = posArray(1,i)
               posArrayGlo_2(2,i) = posArray(2,i)
            enddo
          endif

c        do i=1, npos
c           write(6, '(A6,6I16)') 'npos3', istep, nid, i, 
c    $      posArrayGlo_2(1,i)
c    $    , posArrayGlo_2(2,i)
c        enddo

c     if(nid .eq. 0) then
c     do i =1,np
c        print *, "nposArray", nid, i, nposArray(i)
c     enddo
c     do i = 1,np
c       print *, "npos_array", nid, i, npos_array(i)
c     enddo    

c     do i=1,np
c        print *, 'posArrayGlo_2', nid, i, posArrayGlo_2(1,i)
c    $      , posArrayGlo_2(2,i)
c     enddo
c     endif
c     limit the number of element in a processor
c 20         continue
             do i = 2, np
               if(posArrayGlo_2(2,i)-posArrayGlo_2(2,i-1).gt.lelt) then
                   if(nid .eq. 0)
     $            print *, 'proc ', i-1, 'first exceed lelt, rearranged'
     $                 , posArrayGlo_2(2,i-1), posArrayGlo_2(2,i)
                   posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+lelt
                endif
             enddo
             if(nelgt+1-posArrayGlo_2(2,np) .gt. lelt) then
                posArrayGlo_2(2,np) = nelgt+1-lelt
                do i=np, 2, -1
                 if(posArrayGlo_2(2,i)-posArrayGlo_2(2,i-1).gt.lelt)then
                      if(nid .eq. 0)
     $           print *, 'proc ', i-1, 'second exceed lelt, rearranged'
     $                    , posArrayGlo_2(2,i-1), posArrayGlo_2(2,i)
                      posArrayGlo_2(2,i-1) = posArrayGlo_2(2,i)-lelt
                   else
                      exit
                 endif
                enddo
             endif
c        endif
       endif
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new cenp0', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()
       call bcast(posArrayGlo_2, 4*2*np)
c     print *, 'load of p', i-1, psum(pos(i+1)-1)-psum(pos(i)-1)
c    $                 ,pos(i), pos(i+1)-1
      do i=1,np-1
         do j=posArrayGlo_2(2,i),  posArrayGlo_2(2,i+1)-1
            newgllnid(j)=posArrayGlo_2(1,i)
         enddo
      enddo
      do i = j, nelgt
         newgllnid(i) = np-1
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new rest', endtime-starttime1
      endif
c     if(nid.eq.8 ) then
c       do i = 1, nelgt
c          print *, "newgllnid ", istep,  nid, i, newgllnid(i)
c       enddo
c     endif
c     do i =1, nelgt
c        print *, 'newgllnid', nid, i, newgllnid(i)
c     enddo

      return
      end


c--------------------------------------------------------
c     assign to corresponding processor of gllnid, distributed method
      subroutine ldblce_hybrid_real(psum, newgllnid, totalload)
      include 'mpif.h'
      include 'SIZE'
      include 'PARALLEL'
      include 'CMTPART'
      include 'TSTEP'

      common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal

      real psum(nelt)
      integer newgllnid(nelgt)
      real totalload
      real threshb
      integer diva, ierr, pnelt, m, j
      integer tempgllnid(nelt), preElem
      integer nelt_array_psum(np)
      integer status_mpi(MPI_STATUS_SIZE)
      integer posArray(3, np), npos, nposArray(np), posArrayGlo(2,np)
      integer preSum_npos, npos_array(np), posArrayGlo_2(2,np), indexp
      real starttime1, endtime
      integer mdw, ndw, temp1, temp2
!     posArray store where the element change; for example, if
!     tempgllnid={0,0,0,1,1,1,2,3,3}, posArray=
!     (0,1)(1,4)(2,7)(3,8)

      starttime1 = dnekclock_sync()

      threshb = totalload*1.001/np!1.01 instead of 1.0 is to make sure
                                 !psum(i)/threashb is within [0, np-1]
      if(nid.eq.0) print *, 'totalload', totalload, 'thresh', threshb

      do i = 1, nelt
         diva = AINT((psum(i))*1.0/threshb)
         tempgllnid(i) = diva
c        write(6, '(A9,5I16)') 'psum_hy', istep, nid, 
c    $    i, psum(i), tempgllnid(i)
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new psum', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     send tempgllnid(nelt) to the next processor, except for the last processor
      if(nid .ne. np-1) then
         call mpi_send(tempgllnid(nelt), 1, mpi_integer, nid+1, 0
     $      , nekcomm, ierr)
c        print *, 'send ', nid, nid+1, tempgllnid(nelt)
      endif

      if(nid .ne. 0) then
         call mpi_recv(preElem, 1, mpi_integer, nid-1, 0, nekcomm
     $      , status_mpi, ierr)
c        print *, 'receive ', nid-1, nid, preElem
      endif
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new send_recv', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

cc     Get exclusive prefix sum of nelt, sort it in pnelt
c      pnelt = igl_running_sum_ex(nelt)
c      endtime = dnekclock_sync()
c      if( mod(nid, np/2) .eq. np/2-2) then
c         print *, 'ldblce_dist_new ex_sum1', endtime-starttime1
c      endif
c      starttime1 = dnekclock_sync()

      call izero(posArray, 3*np)
      npos = 0
      if(nid .eq. 0) preElem = -1
      if(preElem .ne. tempgllnid(1)) then
         npos = npos + 1
         posArray(1,npos) = tempgllnid(1)
         posArray(2,npos) = lglel(1)  !1 + pnelt !get the local element id
         posArray(3,npos) = 0  !send to p0
      endif
      preElem = tempgllnid(1)
      do i=2, nelt
          if(preElem .ne. tempgllnid(i)) then
             npos = npos + 1
             posArray(1,npos) = tempgllnid(i)
             posArray(2,npos) = lglel(i)   !i + pnelt !get the global element id
             posArray(3,npos) = 0  !send to p0
             preElem = tempgllnid(i)
          endif
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new preElem', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()
c     do i=1, npos
c        write(6, '(A6,6I16)') 'npos:', nid, i, posArray(1,i)
c    $ , posArray(2,i), posArray(3, i) 
c     enddo
      
      mdw = 3
      ndw = np
      key = 3
      call crystal_ituple_transfer(cr_h, posArray, mdw, npos, ndw, key)
c     print *, "tuple   ***", nid, npos
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new transfer', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

      if(nid .eq. 0) then
         key = 1
         nkey = 1
c        print *, "p0 come here"
         call crystal_ituple_sort(cr_h, posArray, mdw, npos, key, nkey)
         starttime1 = dnekclock() !no sync here
c        do i=1, npos
c           write(6, '(A6,5I16)') 'npos2', nid, i, posArray(1,i)
c    $    , posArray(2,i), posArray(3, i) 
c        enddo

c     copy posArrayGlo to posArrayGlo_2 is to avoid the suitation like
c        follows:
c     posArrayGlo(1,i)  0 2 3 4 5 
c     posArrayGLO(2,i)  1 2 3 4 7
c     that porcessor 1 don't have any load, incurring the error in the
c     limit lelt process.
         call izero(posArrayGlo_2, 2*np)
         if(npos .lt. np) then !there is no above situation   
c          go to 20
c        else 
           posArrayGlo_2(1,1) = posArray(1,1)
           posArrayGlo_2(2,1) = posArray(2,1)
           indexp = 1  
c            if(nid.eq.0) print *, 'posArrayGlo_2', 1,posArrayGlo_2(1,1)
c    $      , posArrayGlo_2(2,1), posArrayGlo(2,1)    
           do i =2, np
             if(posArray(1, indexp+1) .eq. posArrayGlo_2(1,i-1)+1) then
               posArrayGlo_2(1,i) = posArray(1,indexp+1)
               if((posArray(2,indexp+1) .le. posArrayGlo_2(2,i-1)
     $            +lelt).and.(posArray(2,indexp+1)
     $              .gt.posArrayGlo_2(2,i-1))) then
                  posArrayGlo_2(2,i) = posArray(2,indexp+1)
               else if (posArray(2,indexp+1) .gt.
     $            posArrayGlo_2(2,i-1) +lelt) then
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+lelt
               else
                  temp1 = ceiling((posArrayGlo_2(2,i-1) +
     $                   posArray(2,indexp+2))*1.0/2)
                  if(temp>posArrayGlo_2(2,i-1)) then
                    posArrayGlo_2(2,i) = temp
                  else
                    posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1) +1
                  endif
               endif    
              indexp = indexp+1  
             else if(posArray(1,indexp+1).gt.posArrayGlo_2(1,i-1)+1)then
                posArrayGlo_2(1,i) = posArrayGlo_2(1,i-1)+1
                temp2 =ceiling((posArray(2,indexp+1)-
     $             posArrayGlo_2(2,i-1))*1.0/
     $          (posArray(1,indexp+1)-posArrayGlo_2(1,i-1)))
                if(temp2>0) then
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+temp2
                else
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+1
                endif
              endif  
            enddo
          else
            do i = 1, np
               posArrayGlo_2(1,i) = posArray(1,i)
               posArrayGlo_2(2,i) = posArray(2,i)
            enddo
          endif

c     limit the number of element in a processor
c 20         continue
             do i = 2, np
               if(posArrayGlo_2(2,i)-posArrayGlo_2(2,i-1).gt.lelt) then
                   if(nid .eq. 0)
     $            print *, 'proc ', i-1, 'first exceed lelt, rearranged'
     $                 , posArrayGlo_2(2,i-1), posArrayGlo_2(2,i)
                   posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+lelt
                endif
             enddo
             if(nelgt+1-posArrayGlo_2(2,np) .gt. lelt) then
                posArrayGlo_2(2,np) = nelgt+1-lelt
                do i=np, 2, -1
                 if(posArrayGlo_2(2,i)-posArrayGlo_2(2,i-1).gt.lelt)then
                      if(nid .eq. 0)
     $           print *, 'proc ', i-1, 'second exceed lelt, rearranged'
     $                    , posArrayGlo_2(2,i-1), posArrayGlo_2(2,i)
                      posArrayGlo_2(2,i-1) = posArrayGlo_2(2,i)-lelt
                   else
                      exit
                 endif
                enddo
             endif
c        endif
       endif
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new cenp0', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()
       call bcast(posArrayGlo_2, 4*2*np)
c     print *, 'load of p', i-1, psum(pos(i+1)-1)-psum(pos(i)-1)
c    $                 ,pos(i), pos(i+1)-1
      do i=1,np-1
         do j=posArrayGlo_2(2,i),  posArrayGlo_2(2,i+1)-1
            newgllnid(j)=posArrayGlo_2(1,i)
         enddo
      enddo
      do i = j, nelgt
         newgllnid(i) = np-1
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_hybrid_new rest', endtime-starttime1
      endif

      return
      end
c--------------------------------------------------------
c     assign to corresponding processor of gllnid, distributed method
      subroutine ldblce_dist_new(psum, newgllnid)
      include 'mpif.h'
      include 'SIZE'
      include 'PARALLEL'
      include 'CMTPART'
      include 'TSTEP'

      common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal

      integer psum(nelt), newgllnid(nelgt)
      real threshb!, ratio!, threshil, threshh
      integer totalload, diva, ierr, pnelt, m, j
      integer tempgllnid(nelt), preElem
      integer nelt_array_psum(np)
      integer status_mpi(MPI_STATUS_SIZE)
      integer posArray(2, np), npos, nposArray(np), posArrayGlo(2,np)
      integer preSum_npos, npos_array(np), posArrayGlo_2(2,np), indexp
      real starttime1, endtime
      integer temp1, temp2, receivedNpos
      common /f2pratio/ ratio
      real ratio
!     posArray store where the element change; for example, if
!     tempgllnid={0,0,0,1,1,1,2,3,3}, posArray=
!     (0,1)(1,4)(2,7)(3,8)

      starttime1 = dnekclock_sync()
      !ratio = 1.0
      totalload = nw + ceiling(ratio*ceiling(nw*1.0/nelgt))*nelgt
      !print *, nid_, totalload

      threshb = totalload*1.0/np
      if(nid.eq.0) print *, 'totalload', totalload, 'thresh', threshb
     $     , 'ratio', ratio

      do i = 1, nelt
         diva = AINT((psum(i)-1)*1.0/threshb)
         tempgllnid(i) = diva
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new psum', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     send tempgllnid(nelt) to the next processor, except for the last processor
      if(nid .ne. np-1) then
         call mpi_send(tempgllnid(nelt), 1, mpi_integer, nid+1, 0
     $      , nekcomm, ierr)
c        print *, 'send ', nid, nid+1, tempgllnid(nelt)
      endif

      if(nid .ne. 0) then
         call mpi_recv(preElem, 1, mpi_integer, nid-1, 0, nekcomm
     $      , status_mpi, ierr)
c        print *, 'receive ', nid-1, nid, preElem
      endif
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new send_recv', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     Get exclusive prefix sum of nelt, sort it in pnelt
      pnelt = igl_running_sum_ex(nelt)
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new ex_sum1', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

      call izero(posArray, 2*np)
      npos = 0
      if(nid .eq. 0) preElem = -1
      if(preElem .ne. tempgllnid(1)) then
         npos = npos + 1
         posArray(1,npos) = tempgllnid(1)
         posArray(2,npos) = 1 + pnelt !get the local element id
      endif
      preElem = tempgllnid(1)
      do i=2, nelt
          if(preElem .ne. tempgllnid(i)) then
             npos = npos + 1
             posArray(1,npos) = tempgllnid(i)
             posArray(2,npos) = i + pnelt !get the global element id
             preElem = tempgllnid(i)
          endif
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new preElem', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     do i=1, npos
c        write(6, '(A6,6I16)') 'npos', istep, nid, i, posArray(1,i)
c    $ , posArray(2,i)
c     enddo

c     Get exclusive prefix sum of npos, store it in preSum_npos
c     npos   1 2 1 1  (npos_array: number of cut/transition points in processors 
c                       P0, P1, P2, P3) 
c     preSum_npos 0 1 3 4 
c     nposArray   0 1 3 4 in every processor (start position of npos in
c                                             global buffer)
c     print *, 'pos:', nid, npos
c     do i=1,npos
c        print *, 'posArray', nid, i, posArray(1,i)
c    $      , posArray(2,i)
c     enddo
c     do i=1, nelt
c       print *, "tempgllnid", nid, i, tempgllnid(i), psum(i), threshb
c     enddo
      npos = 2*npos !*2 because posArray is 2-d array
      preSum_npos = igl_running_sum_ex(npos)
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new ex_sum2', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()
c     print *, "preSum_npos", nid, preSum_npos, npos
      call mpi_allgather(preSum_npos, 1, mpi_integer, nposArray
     $    , 1,  MPI_INTEGER, nekcomm, ierr)
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new allgather1', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()
c     if(nid .eq.10) then
c     do i=1, np
c        print *, 'nposArray', i, nposArray(i) 
c     enddo
c     endif

c     Get nelt_array for every processor
      call mpi_allgather(npos, 1, mpi_integer, npos_array, 1,
     $   MPI_INTEGER, nekcomm, ierr) !note here, the receive buff is also 1 not np
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new allgather2', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()
c     if(nid .eq.10) then
c     do i=1, np
c        print *, 'npos_array', i, npos_array(i) 
c     enddo
c     endif

c     Gather posArray into posArrayGlo
      call mpi_allgatherv(posArray, npos, mpi_integer, posArrayGlo,
     $   npos_array, nposArray, mpi_integer, nekcomm, ierr)
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new allgatherv', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     print *, 'nposArray', nposArray(np-1), nposArray(np),
c    $  npos_array(np-1), npos_array(np)
      receivedNpos = (nposArray(np)+npos_array(np))/2
c     if(nid.eq.4) then
c        do i=1, receivedNpos
c           write(6, '(A6,7I16)') 'npos2', istep, nid, i,
c    $     posArrayGlo(1,i), posArrayGlo(2,i) !, nposArray(i),
c     $     npos_array(i)
c        enddo
c     endif

c     copy posArrayGlo to posArrayGlo_2 is to avoid the suitation like
c        follows:
c     posArrayGlo(1,i)  0 2 3 4 5 
c     posArrayGLO(2,i)  1 2 3 4 7
c     that porcessor 1 don't have any load, incurring the error in the
c     limit lelt process.
      if(receivedNpos .lt.np) then
         posArrayGlo_2(1,1) = posArrayGlo(1,1)
         posArrayGlo_2(2,1) = posArrayGlo(2,1)
         indexp = 1  
c            if(nid.eq.0) print *, 'posArrayGlo_2', 1,posArrayGlo_2(1,1)
c    $      , posArrayGlo_2(2,1), posArrayGlo(2,1)    
         do i =2, np
           if(posArrayGlo(1, indexp+1) .eq. posArrayGlo_2(1,i-1)+1) then
               posArrayGlo_2(1,i) = posArrayGlo(1,indexp+1)
               if((posArrayGlo(2,indexp+1) .le. posArrayGlo_2(2,i-1)
     $            +lelt).and.(posArrayGlo(2,indexp+1)
     $              .gt.posArrayGlo_2(2,i-1))) then
                 posArrayGlo_2(2,i) = posArrayGlo(2,indexp+1)
               else if (posArrayGlo(2,indexp+1) .gt.
     $            posArrayGlo_2(2,i-1) +lelt) then
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+lelt
               else
                  temp1 = ceiling((posArrayGlo_2(2,i-1) +
     $                   posArrayGlo(2,indexp+2))*1.0/2)
                  if(temp>posArrayGlo_2(2,i-1)) then
                    posArrayGlo_2(2,i) = temp
                  else
                    posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1) +1
                  endif
               endif 
               indexp = indexp+1  
          else if(posArrayGlo(1,indexp+1).gt.posArrayGlo_2(1,i-1)+1)then
                posArrayGlo_2(1,i) = posArrayGlo_2(1,i-1)+1
                temp2 =ceiling((posArrayGlo(2,indexp+1)-
     $             posArrayGlo_2(2,i-1))*1.0/
     $          (posArrayGlo(1,indexp+1)-posArrayGlo_2(1,i-1)))
                if(temp2>0) then
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+temp2
                else
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+1
                endif
            endif
         enddo
      else
         do i = 1, np
            posArrayGlo_2(1,i) = posArrayGlo(1,i)
            posArrayGlo_2(2,i) = posArrayGlo(2,i)
         enddo
      endif 

c     if(nid .eq. 0) then
c     do i =1,np
c        print *, "nposArray", nid, i, nposArray(i)
c     enddo
c     do i = 1,np
c       print *, "npos_array", nid, i, npos_array(i)
c     enddo    

c     if(nid .eq.5) then
c        do i=1, np
c           write(6, '(A6,6I16)') 'npos3', istep, nid, i, 
c    $      posArrayGlo_2(1,i)
c    $    , posArrayGlo_2(2,i)
c        enddo
c     endif
c     endif
c     limit the number of element in a processor
      do i = 2, np
         if(posArrayGlo_2(2,i)-posArrayGlo_2(2,i-1) .gt. lelt) then
            if(nid .eq. 0)
     $      print *, 'proc ', i-1, 'first exceed lelt, rearranged'
     $          , posArrayGlo_2(2,i-1), posArrayGlo_2(2,i)
            posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+lelt
         endif
      enddo
      if(nelgt+1-posArrayGlo_2(2,np) .gt. lelt) then
         posArrayGlo_2(2,np) = nelgt+1-lelt
         do i=np, 2, -1
            if(posArrayGlo_2(2,i)-posArrayGlo_2(2,i-1) .gt. lelt) then
               if(nid .eq. 0)
     $           print *, 'proc ', i-1, 'second exceed lelt, rearranged'
     $             , posArrayGlo_2(2,i-1), posArrayGlo_2(2,i)
               posArrayGlo_2(2,i-1) = posArrayGlo_2(2,i)-lelt
            else
               exit
            endif
         enddo
      endif
c     print *, 'load of p', i-1, psum(pos(i+1)-1)-psum(pos(i)-1)
c    $                 ,pos(i), pos(i+1)-1
      do i=1,np-1
         do j=posArrayGlo_2(2,i),  posArrayGlo_2(2,i+1)-1
            newgllnid(j)=posArrayGlo_2(1,i)
         enddo
      enddo
      do i = j, nelgt
         newgllnid(i) = np-1
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new rest', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     if(nid.eq.8 ) then
c       do i = 1, nelgt
c          print *, "newgllnid ", istep,  nid, i, newgllnid(i)
c       enddo
c     endif

      return
      end

c--------------------------------------------------------
c     assign to corresponding processor of gllnid, distributed method
      subroutine ldblce_dist_real(psum, newgllnid, totalload)
      include 'mpif.h'
      include 'SIZE'
      include 'PARALLEL'
      include 'CMTPART'
      include 'TSTEP'

      common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal

      real psum(nelt)
      integer newgllnid(nelgt)
      real totalload
      real threshb!, ratio!, threshil, threshh
      integer diva, ierr, pnelt, m, j
      integer tempgllnid(nelt), preElem
      integer nelt_array_psum(np)
      integer status_mpi(MPI_STATUS_SIZE)
      integer posArray(2, np), npos, nposArray(np), posArrayGlo(2,np)
      integer preSum_npos, npos_array(np), posArrayGlo_2(2,np), indexp
      real starttime1, endtime
      integer temp1, temp2, receivedNpos
!     posArray store where the element change; for example, if
!     tempgllnid={0,0,0,1,1,1,2,3,3}, posArray=
!     (0,1)(1,4)(2,7)(3,8)

      starttime1 = dnekclock_sync()

      threshb = totalload*1.001/np
      if(nid.eq.0) print *, 'totalload', totalload, 'thresh', threshb

      do i = 1, nelt
         diva = AINT(psum(i)*1.0/threshb)
         tempgllnid(i) = diva
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new psum', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     send tempgllnid(nelt) to the next processor, except for the last processor
      if(nid .ne. np-1) then
         call mpi_send(tempgllnid(nelt), 1, mpi_integer, nid+1, 0
     $      , nekcomm, ierr)
c        print *, 'send ', nid, nid+1, tempgllnid(nelt)
      endif

      if(nid .ne. 0) then
         call mpi_recv(preElem, 1, mpi_integer, nid-1, 0, nekcomm
     $      , status_mpi, ierr)
c        print *, 'receive ', nid-1, nid, preElem
      endif
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new send_recv', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     Get exclusive prefix sum of nelt, sort it in pnelt
      pnelt = igl_running_sum_ex(nelt)
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new ex_sum1', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

      call izero(posArray, 2*np)
      npos = 0
      if(nid .eq. 0) preElem = -1
      if(preElem .ne. tempgllnid(1)) then
         npos = npos + 1
         posArray(1,npos) = tempgllnid(1)
         posArray(2,npos) = 1 + pnelt !get the local element id
      endif
      preElem = tempgllnid(1)
      do i=2, nelt
          if(preElem .ne. tempgllnid(i)) then
             npos = npos + 1
             posArray(1,npos) = tempgllnid(i)
             posArray(2,npos) = i + pnelt !get the global element id
             preElem = tempgllnid(i)
          endif
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new preElem', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     Get exclusive prefix sum of npos, store it in preSum_npos
c     npos   1 2 1 1  (npos_array: number of cut/transition points in processors 
c                       P0, P1, P2, P3) 
c     preSum_npos 0 1 3 4 
c     nposArray   0 1 3 4 in every processor (start position of npos in
c                                             global buffer)
      npos = 2*npos !*2 because posArray is 2-d array
      preSum_npos = igl_running_sum_ex(npos)
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new ex_sum2', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()
      call mpi_allgather(preSum_npos, 1, mpi_integer, nposArray
     $    , 1,  MPI_INTEGER, nekcomm, ierr)
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new allgather1', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     Get nelt_array for every processor
      call mpi_allgather(npos, 1, mpi_integer, npos_array, 1,
     $   MPI_INTEGER, nekcomm, ierr) !note here, the receive buff is also 1 not np
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new allgather2', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     Gather posArray into posArrayGlo
      call mpi_allgatherv(posArray, npos, mpi_integer, posArrayGlo,
     $   npos_array, nposArray, mpi_integer, nekcomm, ierr)
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new allgatherv', endtime-starttime1
      endif
      starttime1 = dnekclock_sync()

c     print *, 'nposArray', nposArray(np-1), nposArray(np),
c    $  npos_array(np-1), npos_array(np)
      receivedNpos = (nposArray(np)+npos_array(np))/2

c     copy posArrayGlo to posArrayGlo_2 is to avoid the suitation like
c        follows:
c     posArrayGlo(1,i)  0 2 3 4 5 
c     posArrayGLO(2,i)  1 2 3 4 7
c     that porcessor 1 don't have any load, incurring the error in the
c     limit lelt process.
      if(receivedNpos .lt.np) then
         posArrayGlo_2(1,1) = posArrayGlo(1,1)
         posArrayGlo_2(2,1) = posArrayGlo(2,1)
         indexp = 1  
c            if(nid.eq.0) print *, 'posArrayGlo_2', 1,posArrayGlo_2(1,1)
c    $      , posArrayGlo_2(2,1), posArrayGlo(2,1)    
         do i =2, np
           if(posArrayGlo(1, indexp+1) .eq. posArrayGlo_2(1,i-1)+1) then
               posArrayGlo_2(1,i) = posArrayGlo(1,indexp+1)
               if((posArrayGlo(2,indexp+1) .le. posArrayGlo_2(2,i-1)
     $            +lelt).and.(posArrayGlo(2,indexp+1)
     $              .gt.posArrayGlo_2(2,i-1))) then
                 posArrayGlo_2(2,i) = posArrayGlo(2,indexp+1)
               else if (posArrayGlo(2,indexp+1) .gt.
     $            posArrayGlo_2(2,i-1) +lelt) then
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+lelt
               else
                  temp1 = ceiling((posArrayGlo_2(2,i-1) +
     $                   posArrayGlo(2,indexp+2))*1.0/2)
                  if(temp>posArrayGlo_2(2,i-1)) then
                    posArrayGlo_2(2,i) = temp
                  else
                    posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1) +1
                  endif
               endif 
               indexp = indexp+1  
          else if(posArrayGlo(1,indexp+1).gt.posArrayGlo_2(1,i-1)+1)then
                posArrayGlo_2(1,i) = posArrayGlo_2(1,i-1)+1
                temp2 =ceiling((posArrayGlo(2,indexp+1)-
     $             posArrayGlo_2(2,i-1))*1.0/
     $          (posArrayGlo(1,indexp+1)-posArrayGlo_2(1,i-1)))
                if(temp2>0) then
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+temp2
                else
                  posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+1
                endif
            endif
         enddo
      else
         do i = 1, np
            posArrayGlo_2(1,i) = posArrayGlo(1,i)
            posArrayGlo_2(2,i) = posArrayGlo(2,i)
         enddo
      endif 

c     limit the number of element in a processor
      do i = 2, np
         if(posArrayGlo_2(2,i)-posArrayGlo_2(2,i-1) .gt. lelt) then
            if(nid .eq. 0)
     $      print *, 'proc ', i-1, 'first exceed lelt, rearranged'
     $          , posArrayGlo_2(2,i-1), posArrayGlo_2(2,i)
            posArrayGlo_2(2,i) = posArrayGlo_2(2,i-1)+lelt
         endif
      enddo
      if(nelgt+1-posArrayGlo_2(2,np) .gt. lelt) then
         posArrayGlo_2(2,np) = nelgt+1-lelt
         do i=np, 2, -1
            if(posArrayGlo_2(2,i)-posArrayGlo_2(2,i-1) .gt. lelt) then
               if(nid .eq. 0)
     $           print *, 'proc ', i-1, 'second exceed lelt, rearranged'
     $             , posArrayGlo_2(2,i-1), posArrayGlo_2(2,i)
               posArrayGlo_2(2,i-1) = posArrayGlo_2(2,i)-lelt
            else
               exit
            endif
         enddo
      endif
c     print *, 'load of p', i-1, psum(pos(i+1)-1)-psum(pos(i)-1)
c    $                 ,pos(i), pos(i+1)-1
      do i=1,np-1
         do j=posArrayGlo_2(2,i),  posArrayGlo_2(2,i+1)-1
            newgllnid(j)=posArrayGlo_2(1,i)
         enddo
      enddo
      do i = j, nelgt
         newgllnid(i) = np-1
      enddo
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'ldblce_dist_new rest', endtime-starttime1
      endif
      return
      end
c-----------------------------------------------------------------

c      print array real
       subroutine printr(pload, len)
          real pload(len)
          integer i
          do 40 i=1, len
             print *, pload(i)
   40     continue
       return
       end

c      print array integer
       subroutine printi(pos, len)
          integer pos(len)
          integer i
          do 40 i=1, len
             print *, pos(i)
   40     continue
       return
       end


c------------------------------------------------------------------
c     recompute partitions
       subroutine recompute_partitions_distr
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'TSTEP'          
          include 'SOLN'          
          include 'CMTPART'          
          include 'CMTDATA'          
 
          common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal
          common /elementload/ gfirst, inoassignd, 
     >                 resetFindpts, pload(lelg)
          integer gfirst, inoassignd, resetFindpts, pload
          integer newgllnid(lelg), trans(3, lelg), trans_n, psum(lelt)
          integer e,eg,eg0,eg1,mdw,ndw
          integer ntuple, i, el, delta, nxyz
          common /f2pratio/ ratio
          real ratio

          integer gaselement(np), ierr, nn, partialload, totalload
          !real ratio

          if(nid_ .eq. 0) then
             print *, 'in recompute_partitions_distr'
          endif
          starttime = dnekclock_sync()
          nxyz = nx1*ny1*nz1   !total # of grid point per element
          delta = ceiling(nw*1.0/nelgt)
          !ratio = 1.0
          ntuple = nelt

          call izero(pload, lelg) 
          do ip=1,n
             el = ipart(je0, ip) + 1      ! element id in ipart is start from 0, so add 1
             pload(el) = pload(el)+1
          enddo

          do i=1,ntuple
             pload(i) = pload(i) + ceiling(delta*ratio)
          enddo

           call izero(psum, lelt)
           call preSum(pload, psum, nelt)

           nn = psum(nelt)
           partialload= igl_running_sum_ex(nn) !exclusive prefix sum
c         if( mod(nid, np/2) .eq. np/2-2 .or. nid .eq.0) then
c         print *, " igl_running_sum_ex" , dnekclock() - t0, t0,
c    $        dnekclock()
c         endif

c          now every processor has the actual prefix sum
           do i=1, nelt
              psum(i) = psum(i) + partialload
           enddo

           call izero(newgllnid, lelg)
           endtime = dnekclock_sync()
           if( mod(nid, np/2) .eq. np/2-2) then
              print *, "before ldblce_dist_new" , endtime - starttime
           endif
           t0 = dnekclock_sync()
           call ldblce_dist_new(psum, newgllnid)
           endtime = dnekclock_sync()
           if( mod(nid, np/2) .eq. np/2-2) then
               print *, "in ldblce_dist_new" , endtime - t0
          endif
           t0 = dnekclock_sync()

          call izero(trans, 3*lelg)
          call track_elements(gllnid, newgllnid, nelgt, trans,
     $                               trans_n, lglel)

          call track_particles(trans, trans_n)
          endtime = dnekclock_sync()
          if( mod(nid, np/2) .eq. np/2-2) then
              print *, "Component 0:" , endtime - starttime!, starttime,
              print *, "after ldblce_dist_new:" , endtime - t0
          endif
          call mergeArray(phig, lx1*ly1*lz1, lelt, newgllnid, 'phig')
          call mergeArray(u, lx1*ly1*lz1*toteq, lelt, newgllnid, 'u')
          call mergeTlagArray_new(newgllnid)
          call mergeArray(xc, 8, lelt, newgllnid, 'xc')
          call mergeArray(yc, 8, lelt, newgllnid, 'yc')
          call mergeArray(zc, 8, lelt, newgllnid, 'zc')
          call mergeArray(curve, 6*12, lelt, newgllnid, 'curve')
          call mergeArrayC(ccurve, 12, lelt, newgllnid, 'ccurve')
          call mergeBcArray(newgllnid)
          call mergeCbcArray(newgllnid)

          call icopy(gllnid, newgllnid, nelgt)
              
          return
          end

c------------------------------------------------------------------
c     recompute partitions
       subroutine recompute_partitions_vers2_dist
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'TSTEP'          
          include 'SOLN'          
          include 'CMTPART'          
          include 'CMTDATA'          
          include 'CMTTIMERS'          
 
          common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal
          common /elementload/ gfirst, inoassignd, 
     >                 resetFindpts, pload(lelg)
          integer gfirst, inoassignd, resetFindpts, pload
          integer newgllnid(lelg), trans(3, lelg), trans_n
          real psum(lelt)
          integer e,eg,eg0,eg1,mdw,ndw
          integer ntuple, i, el, delta, nxyz
          integer ierr 
          real nn, partialload, totalload

          common /computeload/ compload
          real compload(lelg)
          logical partl
          integer nl


          if(nid .eq. 0) then
             write(6, *) 'in recompute_partitions_vers2_dist'
          endif
          starttime = dnekclock_sync()
          nxyz = nx1*ny1*nz1   !total # of grid point per element
          ntuple = nelt

          call rzero(compload, lelg) 
          call izero(pload, lelg) 
          do ip=1,n
             el = ipart(je0, ip) + 1      ! element id in ipart is start from 0, so add 1
             pload(el) = pload(el)+1
          enddo

          do i=1,ntuple
             if(n .eq. 0) then
                compload(i) = fluid_time/nelt + p_time/nelt
             else
                compload(i) = fluid_time/nelt + p_time/n*pload(i)
             endif
             !write(6,*) "pload: ", nid, i, compload(i)
          enddo

           call rzero(psum, lelt)
           call preSumr(compload, psum, nelt)

           nn = psum(nelt)
           partialload= gl_running_sum_ex(nn) !exclusive prefix sum
           totalload = glsum(nn, 1) 
           write(6,"A15, I8, 3F30.16") "totalload: ", nid, nn, 
     $ partialload, totalload 
           !do i = 1, nelt
           !   write(6,*) "psum: ", nid, i, psum(i)
           !enddo

c          now every processor has the actual prefix sum
           do i=1, nelt
              psum(i) = psum(i) + partialload
           enddo

           call izero(newgllnid, lelg)
           endtime = dnekclock_sync()
           if( mod(nid, np/2) .eq. np/2-2) then
              print *, "before ldblce_dist_real" , endtime - starttime
           endif
           t0 = dnekclock_sync()
           call ldblce_dist_real(psum, newgllnid, totalload)
           endtime = dnekclock_sync()
           if( mod(nid, np/2) .eq. np/2-2) then
               print *, "in ldblce_dist_real" , endtime - t0
          endif
          if(nid .eq. 0) then
             do i=1, nelgt
                write(6,*) "newgllnid ", istep, i, newgllnid(i)
             enddo
          endif
           t0 = dnekclock_sync()

          call izero(trans, 3*lelg)
          call track_elements(gllnid, newgllnid, nelgt, trans,
     $                               trans_n, lglel)

          call track_particles(trans, trans_n)
          endtime = dnekclock_sync()
          if( mod(nid, np/2) .eq. np/2-2) then
              print *, "Component 0:" , endtime - starttime!, starttime,
              print *, "after ldblce_dist_new:" , endtime - t0
          endif
          call mergeArray(phig, lx1*ly1*lz1, lelt, newgllnid, 'phig')
          call mergeArray(u, lx1*ly1*lz1*toteq, lelt, newgllnid, 'u')
          call mergeTlagArray_new(newgllnid)
          call mergeArray(xc, 8, lelt, newgllnid, 'xc')
          call mergeArray(yc, 8, lelt, newgllnid, 'yc')
          call mergeArray(zc, 8, lelt, newgllnid, 'zc')
          call mergeArray(curve, 6*12, lelt, newgllnid, 'curve')
          call mergeArrayC(ccurve, 12, lelt, newgllnid, 'ccurve')
          call mergeBcArray(newgllnid)
          call mergeCbcArray(newgllnid)

          call icopy(gllnid, newgllnid, nelgt)
              
          return
          end


c------------------------------------------------------------------
c     recompute partitions
       subroutine recompute_partitions_hybrid
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'TSTEP'          
          include 'SOLN'          
          include 'CMTPART'          
          include 'CMTDATA'          
 
          common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal
          common /elementload/ gfirst, inoassignd, 
     >                 resetFindpts, pload(lelg)
          integer gfirst, inoassignd, resetFindpts, pload

          integer newgllnid(lelg), trans(3, lelg), trans_n, psum(lelg)
          integer e,eg,eg0,eg1,mdw,ndw
          integer ntuple, i, el, delta, nxyz
          common /f2pratio/ ratio
          real ratio

          integer gaselement(np), ierr, nn, partialload, totalload
          !real ratio
          real starttime, endtime, t0

          if(nid_ .eq. 0) then
             print *, 'in recompute_partitions_hybrid'
          endif
          
          starttime = dnekclock_sync()
          nxyz = nx1*ny1*nz1   !total # of grid point per element
          call izero(pload, lelg)
          delta = ceiling(nw*1.0/nelgt)
          !ratio = 1.0
          ntuple = nelt

          do ip=1,n
             el = ipart(je0, ip) + 1      ! element id in ipart is start from 0, so add 1
             pload(el) = pload(el)+1
          enddo

          do i=1,ntuple
             pload(i) = pload(i) + ceiling(delta*ratio)
          enddo

          call izero(psum, lelt)
          call preSum(pload, psum, nelt)

          nn = psum(nelt)
          partialload= igl_running_sum_ex(nn)

          do i=1, nelt
              psum(i) = psum(i) + partialload
           enddo

          call izero(newgllnid, lelg)
          endtime = dnekclock_sync()
          if( mod(nid, np/2) .eq. np/2-2) then
              print *, "before ldblce_hybrid_new" , endtime - starttime
          endif
          t0 = dnekclock_sync() 
          call ldblce_hybrid(psum, newgllnid) 
          endtime = dnekclock_sync()
          if( mod(nid, np/2) .eq. np/2-2) then
              print *, "in ldblce_hybrid_new" , endtime - t0
          endif

          t0 = dnekclock_sync() 

          call izero(trans, 3*lelg)
          call track_elements(gllnid, newgllnid, nelgt, trans, 
     $                               trans_n, lglel)
          call track_particles(trans, trans_n)
          endtime = dnekclock_sync()
          if( mod(nid, np/2) .eq. np/2-2 ) then
              print *, "Component 0:" , endtime - starttime !, starttime,
              print *, "after ldblce_hybrid_new:" , endtime - t0
          endif
          call mergeArray(phig, lx1*ly1*lz1, lelt, newgllnid, 'phig')
          !print *, "complelt phig", nid
          call mergeArray(u, lx1*ly1*lz1*toteq, lelt, newgllnid, 'u')
          !print *, "complelt u", nid
          call mergeTlagArray_new(newgllnid)
          call mergeArray(xc, 8, lelt, newgllnid, 'xc')   
          call mergeArray(yc, 8, lelt, newgllnid, 'yc')
          call mergeArray(zc, 8, lelt, newgllnid, 'zc')
          call mergeArray(curve, 6*12, lelt, newgllnid, 'curve')
          call mergeArrayC(ccurve, 12, lelt, newgllnid, 'ccurve')  
          call mergeBcArray(newgllnid) 
          call mergeCbcArray(newgllnid) 

          call icopy(gllnid, newgllnid, nelgt)

          return
          end


c------------------------------------------------------------------
c     recompute partitions
       subroutine recompute_partitions_vers2_hybrid
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'TSTEP'          
          include 'SOLN'          
          include 'CMTPART'          
          include 'CMTDATA'          
          include 'CMTTIMERS'          
 
          common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal
          common /elementload/ gfirst, inoassignd, 
     >                 resetFindpts, pload(lelg)
          integer gfirst, inoassignd, resetFindpts, pload

          integer newgllnid(lelg), trans(3, lelg), trans_n
          real psum(lelg)
          integer e,eg,eg0,eg1,mdw,ndw
          integer ntuple, i, el, delta, nxyz

          integer ierr
          real nn, partialload, totalload
          real starttime, endtime, t0

          common /computeload/ compload
          real compload(lelg)
          logical partl
          integer nl 

          if(nid_ .eq. 0) then
             write(6,*)  'in recompute_partitions_vers2_hybrid'
          endif
          
          starttime = dnekclock_sync()
          nxyz = nx1*ny1*nz1   !total # of grid point per element
          call rzero(compload, lelg)
          call izero(pload, lelg)
          ntuple = nelt

          do ip=1,n
             el = ipart(je0, ip) + 1      ! element id in ipart is start from 0, so add 1
             pload(el) = pload(el)+1
          enddo

          do i=1,ntuple
             if(n .eq. 0) then
                compload(i) = fluid_time/nelt + p_time/nelt
             else
                compload(i) = fluid_time/nelt + p_time/n*pload(i)
             endif
             !pload(i) = pload(i) + ceiling(delta*ratio)
          enddo

          call rzero(psum, lelt)
          call preSumr(compload, psum, nelt)

          nn = psum(nelt)
          partialload= gl_running_sum_ex(nn)
          totalload = glsum(nn, 1)
          write(6,"A15, I8, 3F30.16") "totalload: ", nid, nn, 
     $ partialload, totalload 

          do i=1, nelt
              psum(i) = psum(i) + partialload
c             write(6, *) 'psum:', nid, lglel(i),psum(i), 
c    $ AINT((psum(i)-1E-10)/threshb) 
           enddo

          call izero(newgllnid, lelg)
          endtime = dnekclock_sync()
          if( mod(nid, np/2) .eq. np/2-2) then
              print *, "before ldblce_hybrid_real" , endtime - starttime
          endif
          t0 = dnekclock_sync() 
          call ldblce_hybrid_real(psum, newgllnid, totalload) 
          endtime = dnekclock_sync()
          if( mod(nid, np/2) .eq. np/2-2) then
              print *, "in ldblce_hybrid_real" , endtime - t0
          endif
c         if(nid .eq. 0) then
c            do i=1, nelgt
c               write(6,*) "newgllnid ", istep, i, newgllnid(i)
c            enddo
c         endif

          t0 = dnekclock_sync() 

          call izero(trans, 3*lelg)
          call track_elements(gllnid, newgllnid, nelgt, trans, 
     $                               trans_n, lglel)
          call track_particles(trans, trans_n)
          endtime = dnekclock_sync()
          if( mod(nid, np/2) .eq. np/2-2 ) then
              print *, "Component 0:" , endtime - starttime !, starttime,
              print *, "after ldblce_hybrid_real:" , endtime - t0
          endif
          call mergeArray(phig, lx1*ly1*lz1, lelt, newgllnid, 'phig')
          !print *, "complelt phig", nid
          call mergeArray(u, lx1*ly1*lz1*toteq, lelt, newgllnid, 'u')
          !print *, "complelt u", nid
          call mergeTlagArray_new(newgllnid)
          call mergeArray(xc, 8, lelt, newgllnid, 'xc')   
          call mergeArray(yc, 8, lelt, newgllnid, 'yc')
          call mergeArray(zc, 8, lelt, newgllnid, 'zc')
          call mergeArray(curve, 6*12, lelt, newgllnid, 'curve')
          call mergeArrayC(ccurve, 12, lelt, newgllnid, 'ccurve')  
          call mergeBcArray(newgllnid) 
          call mergeCbcArray(newgllnid) 

          call icopy(gllnid, newgllnid, nelgt)

          return
          end
c------------------------------------------------------------------
c     recompute partitions
       subroutine recompute_partitions
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'TSTEP'          
          include 'SOLN'          
          include 'CMTPART'          
          include 'CMTDATA'          
 
c         parameter (lr=76,li=10)
          common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal
          common /elementload/ gfirst, inoassignd, 
     >                 resetFindpts, pload(lelg)
          integer gfirst, inoassignd, resetFindpts, pload

c         integer nw
c         common /particlenumber/ nw

          integer newgllnid(lelg), trans(3, lelg), trans_n, psum(lelg)
          integer e,eg,eg0,eg1,mdw,ndw
          integer ntuple, i, el, delta, nxyz
c     common /ptpointers/ jrc,jpt,je0,jps,jpid1,jpid2,jpid3,jpnn,jpid
c    >                   ,jai,nai,    jr,jd,jx,jy,jz,jv0,ju0,jf0,jfusr
c    >                   ,jfqs,jfun,jfiu,jtaup,jcd,jdrhodt,jre,jDuDt
c    >                   ,jtemp,jrho,jrhop,ja,jvol,jdp,jar,jx1,jx2,jx3
c    >                   ,jv1,jv2,jv3,ju1,ju2,ju3,nar,jvol1,jgam

c         common  /cparti/ ipart(li,llpart)

c         common  /iparti/ n,nr,ni
          integer particleMap(3, lelg)
          integer gaselement(np)
          !real ratio
          common /f2pratio/ ratio
          real ratio
          
c         if(nid .eq. 0) then
c             print *, 'old pload:'
c             call printi(pload, nelgt)
c         endif
          call nekgsync()
          starttime = dnekclock()
          nxyz = nx1*ny1*nz1   !total # of grid point per element
          delta = ceiling(nw*1.0/nelgt)
          !ratio = 1.0
          ntuple = nelt
c         if(nid .eq. 0) then
c            print *, 'delta:', delta, 'nw:', nw, 'ntuple:', ntuple
c            print *, 'starttime', starttime 
c         endif
          do i=1,ntuple
             eg = lglel(i)
             particleMap(1,i) = eg
             particleMap(2,i) = 0        ! processor id to send for element eg
             particleMap(3, i) = 0      !  #of particles in each element, reinitialize to 0, otherwise it keeps the previous value
          enddo

          do ip=1,n
             el = ipart(je0, ip) + 1      ! element id in ipart is start from 0, so add 1
c            print *, 'ipart, nid', istep,  nid, ip, el, ntuple
             particleMap(3, el) = particleMap(3, el) + 1
          enddo

c         gas_right_boundary = exp(TIME/2.0)



          do i=1,ntuple
c            x_left_boundary = xerange(1,1,i)
c            if (x_left_boundary .lt. gas_right_boundary) then
c            !if (vx(1,1,1,i) .ne. 0) then
c               print *, 'istep, nid',istep,  nid, 'particle map', 
c    $            i, particleMap(1,i)
c    $           ,particleMap(2,i),particleMap(3,i)
            particleMap(3, i) = particleMap(3, i) + ceiling(delta*ratio)
c            else
c               particleMap(3, i) = 0
c            endif
          enddo
          mdw=3
          ndw=nelgt
          key = 2  ! processor id is in wk(2,:)
          call crystal_ituple_transfer(cr_h,particleMap,
     $                                 mdw,ntuple,ndw,key)
          
c          total=lelt*10
          
          if (nid .eq. 0) then
             key=1
             nkey = 1
             call crystal_ituple_sort(cr_h,particleMap,mdw,
     $                                ntuple,key,nkey)
             do i=1,ntuple
                pload(i) = particleMap(3, i)
             enddo

c            print *, 'new pload:'
c            call printi(pload, nelgt)
             !print *, 'new pload/n'
             !call printr(newPload, lelt)
             call izero(psum, lelg)
             call preSum(pload, psum, nelgt)
             print *, 'recompute_partitions: psum(nelgt): ', psum(nelgt)
             print *, 'ratio:', ratio, 'thresh:', psum(nelgt)*1.0/np_
             !call printr(newPload, lelt)
             
c            do i=1, nelgt
c               print *, 'psum', i, psum(i)
c            enddo 
             call izero(newgllnid, lelg) 
             print *, "before ldblce_limit", dnekclock()-starttime
c    $            ,starttime, dnekclock()
             t0 = dnekclock()  
             call ldblce_limit(psum, nelgt, newgllnid, np_)
             print *, "in ldblce_limit", dnekclock()-t0
             t0 = dnekclock()  
c            do i=1, nelgt
c               print *, 'newgllnid', i, newgllnid(i)
c            enddo 

c            print *, 'print new gllnid'
c            call printi(newgllnid, nelgt)
c            call izero(gaselement, np)
c            do i=1, nelgt
c               if (pload(i) .ne. 0) then
c               gaselement(newgllnid(i)+1)=gaselement(newgllnid(i)+1)+1
c               endif
c            enddo 
c            do i=1, np
c                print *, '# gas element on', i-1, 'is: ', gaselement(i)
c            enddo
          endif
          call bcast(newgllnid,4*nelgt)

          call izero(trans, 3*lelg)
          call track_elements(gllnid, newgllnid, nelgt, trans, 
     $                               trans_n, lglel)
c         print *, 'print trans'
c         do 110 i=1, trans_n
c           print *, 'trans', trans(1, i), trans(2, i), trans(3, i)
c 110  continue

          call track_particles(trans, trans_n)
          call nekgsync()
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2 .or. nid .eq. 0) then
          print *, "Component 0:" , endtime - starttime !, starttime,
c    $                     endtime 
          endif
          if( nid .eq.0) then
          print *, "after ldblce_limit:" , endtime - t0 
          endif
c         call mergePhigArray(newgllnid, trans, trans_n)
c         call mergePhigArray_new(newgllnid)
c         call mergeUArray_new(newgllnid)
          call mergeArray(phig, lx1*ly1*lz1, lelt, newgllnid, 'phig')
c         print *, 'complete merge phig', nid
          call mergeArray(u, lx1*ly1*lz1*toteq, lelt, newgllnid, 'u')
c         print *, 'complete merge u', nid
c         call mergeUArray(newgllnid)
c         call mergeTlagArray(newgllnid)
          call mergeTlagArray_new(newgllnid)
c         print *, 'complete merge tlag', nid
          call mergeArray(xc, 8, lelt, newgllnid, 'xc')   
          call mergeArray(yc, 8, lelt, newgllnid, 'yc')
          call mergeArray(zc, 8, lelt, newgllnid, 'zc')
          call mergeArray(curve, 6*12, lelt, newgllnid, 'curve')
          call mergeArrayC(ccurve, 12, lelt, newgllnid, 'ccurve')  
          call mergeBcArray(newgllnid) 
          call mergeCbcArray(newgllnid) 

          call icopy(gllnid, newgllnid, nelgt)
c         print *, 'did icopy', nid

          return
          end
          

c------------------------------------------------------------------
c     recompute partitions centralized, load balance version 2
       subroutine recompute_partitions_vers2_cen
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'TSTEP'          
          include 'SOLN'          
          include 'CMTPART'          
          include 'CMTDATA'          
          include 'CMTTIMERS'          
 
          common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal
          common /elementload/ gfirst, inoassignd, 
     >                 resetFindpts, pload(lelg)
          integer gfirst, inoassignd, resetFindpts, pload
          integer newgllnid(lelg), trans(3, lelg), trans_n
          real psum(lelg)
          integer e,eg,eg0,eg1,mdw,ndw
          integer ntuple, i, el, delta, nxyz
          integer particleMap(3, lelg)

          common /computeload/ compload
          real compload(lelg)
          real tempload(lelg)          
          common /myparth/ i_fp_hndl, i_cr_hndl
          logical partl
          integer nl
        
          nl = 0
          call nekgsync()
          starttime = dnekclock()
          nxyz = nx1*ny1*nz1   !total # of grid point per element
          ntuple = nelt
          do i=1,ntuple
             eg = lglel(i)
             particleMap(1,i) = eg
             particleMap(2,i) = 0        ! processor id to send for element eg
             particleMap(3,i) = 0        ! processor id to send for element eg
             tempload(i) = 0.0      !  #of particles in each element, reinitialize to 0, otherwise it keeps the previous value
          enddo
          if(n .ne. 0) then
            write(6,"A10, 3I7, 4F9.4") "inlb_time:", nid, nelt, n
     $ , fluid_time, p_time,
     $ fluid_time/nelt, p_time/n
          else
            write(6,"A10, 3I7, 4F9.4") "inlb_time2", nid, nelt, n
     $ , fluid_time, p_time,
     $ fluid_time/nelt, p_time/nelt
          endif

          do ip=1,n
             el = ipart(je0, ip) + 1      ! element id in ipart is start from 0, so add 1
c            print *, 'ipart, nid', istep,  nid, ip, el, ntuple
             particleMap(3, el) = particleMap(3, el) + 1
          enddo

          do i=1,ntuple
            if(n .eq. 0) then
               tempload(i) = fluid_time/nelt + p_time/nelt 
            else
              tempload(i) = fluid_time/nelt + p_time/n*particleMap(3, i)
            endif
          enddo

          key = 2  ! processor id is in wk(2,:)
          call crystal_tuple_transfer(i_cr_hndl, ntuple, lelg, 
     $          particleMap, 3, partl, nl, tempload, 1, key)
          
          
          if (nid .eq. 0) then
             key=1
             nkey = 1
             call crystal_tuple_sort(i_cr_hndl, ntuple, particleMap,
     $                            3, partl, nl, tempload, 1,key,nkey)
             do i=1,ntuple
                compload(i) = tempload(i)
             enddo

             call rzero(psum, lelg)
             call preSumr(compload, psum, nelgt)
             print *, 'recompute_partitions_ver2_cen: psum(nelgt): '
     $          , psum(nelgt), 'thresh:', psum(nelgt)/np_
             
             call izero(newgllnid, lelg) 
             print *, "before ldblce_limit", dnekclock()-starttime
             t0 = dnekclock()  
             call ldblce_limit_real(psum, nelgt, newgllnid, np_)
             print *, "in ldblce_limit", dnekclock()-t0
             t0 = dnekclock()  
             do i=1, nelgt
              print *, 'newgllnid', istep,i, newgllnid(i), 
     $ particleMap(3, i), compload(i), psum(i)
             enddo 
             !if(istep .eq. 2) stop

          endif
          call bcast(newgllnid,4*nelgt)

          call izero(trans, 3*lelg)
          call track_elements(gllnid, newgllnid, nelgt, trans, 
     $                               trans_n, lglel)
c         print *, 'print trans'
c         do 110 i=1, trans_n
c           print *, 'trans', trans(1, i), trans(2, i), trans(3, i)
c 110  continue

          call track_particles(trans, trans_n)
          call nekgsync()
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2 .or. nid .eq. 0) then
          print *, "Component 0:" , endtime - starttime !, starttime,
c    $                     endtime 
          endif
          if( nid .eq.0) then
          print *, "after ldblce_limit:" , endtime - t0 
          endif
          call mergeArray(phig, lx1*ly1*lz1, lelt, newgllnid, 'phig')
c         print *, 'complete merge phig', nid
          call mergeArray(u, lx1*ly1*lz1*toteq, lelt, newgllnid, 'u')
c         print *, 'complete merge u', nid
          call mergeTlagArray_new(newgllnid)
c         print *, 'complete merge tlag', nid
          call mergeArray(xc, 8, lelt, newgllnid, 'xc')   
          call mergeArray(yc, 8, lelt, newgllnid, 'yc')
          call mergeArray(zc, 8, lelt, newgllnid, 'zc')
          call mergeArray(curve, 6*12, lelt, newgllnid, 'curve')
          call mergeArrayC(ccurve, 12, lelt, newgllnid, 'ccurve')  
          call mergeBcArray(newgllnid) 
          call mergeCbcArray(newgllnid) 

          call icopy(gllnid, newgllnid, nelgt)

          return
          end
          
c------------------------------------------------------
c subroutine of track elements to be send and received
       subroutine track_elements(gllnid, newgllnid, len, trans, 
     $                     trans_n, lglel)
       include 'SIZE'
       integer gllnid(len), newgllnid(len), trans(3, len), trans_n
       integer lglel(1)
       !trans: first column stores the source pid, second column stores the target pid, the third column stores the element id
       integer i, j; !local variable

       trans_n=1;
       j=0;
       do i=1, len
          if ((gllnid(i) .eq. nid)) then
             j = j+1;
             if(gllnid(i) .ne. newgllnid(i)) then
c since added gllnid(i) .eq. nid, right now, the trans in processor i only store the elements that he shold send. Not all the processors.            
             trans(1, trans_n) = gllnid(i);
             trans(2, trans_n) = newgllnid(i);
             trans(3, trans_n) = lglel(j)
             trans_n=trans_n+1;
           endif
         endif
       enddo
       trans_n=trans_n-1;  !the length of trans
c      print *, trans_n, 'print again in track elements'
c       do 110 i=1, trans_n
          !do 120 j=1, width
c           print *, i, trans(i,1), trans(i,2), trans(i,3)
c  120     continue
c  110  continue

       return
       end
 
c-----------------------------------------------------
c update the particles that are in the elements to be
c transferred, and set jpt to the destination processor
       subroutine track_particles(trans, trans_n)
       include 'SIZE'
       include 'PARALLEL' 
       include 'CMTPART' 

       integer trans(3, lelg), trans_n
C      parameter (lr=76,li=10)
c      common  /iparti/ n,nr,ni
c      common  /cpartr/ rpart(lr,llpart) ! Minimal value of lr = 16*ndim
c      common  /cparti/ ipart(li,llpart) ! Minimal value of li = 5
c      common /ptpointers/ jrc,jpt,je0,jps,jpid1,jpid2,jpid3,jpnn,jai
c    >                ,nai,jr,jd,jx,jy,jz,jx1,jx2,jx3,jv0,jv1,jv2,jv3
c    >                ,ju0,ju1,ju2,ju3,jf0,jar,jaa,jab,jac,jad,nar,jpid
c     common /ptpointers/ jrc,jpt,je0,jps,jpid1,jpid2,jpid3,jpnn,jpid
c    >                   ,jai,nai,    jr,jd,jx,jy,jz,jv0,ju0,jf0,jfusr
c    >                   ,jfqs,jfun,jfiu,jtaup,jcd,jdrhodt,jre,jDuDt
c    >                   ,jtemp,jrho,jrhop,ja,jvol,jdp,jar,jx1,jx2,jx3
c    >                   ,jv1,jv2,jv3,ju1,ju2,ju3,nar,jvol1,jgam

       common /myparth/ i_fp_hndl, i_cr_hndl
     
       
       integer ip, it, e
       logical partl         ! This is a dummy placeholder, used in cr()
       nl = 0                ! No logicals exchanged

       
c     change ipart(je0,i) to global element id
       ip=0
       do ip = 1, n
           e = ipart(je0, ip) + 1 ! je0 start from 0
           ipart(je0, ip) = lglel(e)
       enddo

       do ip = 1, n
          !e = ipart(je0,ip)
          do it = 1, trans_n
             if(ipart(je0, ip) .eq. trans(3, it)) then  
                ipart(jpt, ip) = trans(2, it) !new processor
                exit
             endif
          enddo
          ipart(jps, ip) = ipart(jpt, ip)
       enddo 

       call crystal_tuple_transfer(i_cr_hndl,n,llpart
     $              , ipart,ni,partl,nl,rpart,nr,jps)


       return 
       end 

c------------------------------------------------------
c subroutine to merge  arrays character
       subroutine mergeArrayC(arrayName, len1, len2, newgllnid, atype)
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'
          include 'CMTDATA'

          integer newgllnid(lelg), trans(3, lelg), len1, len2
          character arrayName(len1, len2)
          character tempArray(len1, len2)
          logical partl
          integer nl, sid, eid
          integer key, nkey, trans_n, nxyz
c         integer atype
          character (len=*), intent(in):: atype

          starttime = dnekclock()
          trans_n=0
          nxyz = len1
          nl=0
          do i=1, nelt
              trans_n = trans_n +1
              ieg = lglel(i)
              if (gllnid(ieg) .eq. nid) then
                  trans(1, trans_n) = gllnid(ieg)
                  trans(2, trans_n) = newgllnid(ieg)
                  trans(3, trans_n) = ieg
                  do l=1, nxyz
                     tempArray(l, trans_n) = arrayName(l,i)
                  enddo
              endif
          enddo
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
                print *, "Component 1 ", trim(atype), endtime-starttime
          endif
c          print *, index_n, trans_n, lelt, nid
          starttime = dnekclock()
          key=2
          call crystal_ctuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, tempArray,nxyz,key)
c         print *, 'nid: ', nid, 'trans_n', trans_n
          key=3
          nkey=1
          call crystal_ctuple_sort(cr_h, trans_n, trans, 3,
     $               partl, nl, tempArray, nxyz, key,nkey)
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
             print *, "Component 2 ", trim(atype), endtime-starttime
          endif

          !Update u
          ! set sid and eid
          starttime = dnekclock()
          !copy tempu to u
              do i=1, trans_n
                  do l=1, nxyz
                     arrayName(l,i) = tempArray(l, i)
                  enddo
              enddo
c      print *, "Update u array: u_n", u_n
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
             print *, "Component 3 ", trim(atype), endtime-starttime
          endif
       end
c------------------------------------------------------
c subroutine to merge  arrays
          subroutine mergeArray(arrayName, len1, len2, newgllnid, atype)
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'CMTDATA'          

          integer newgllnid(lelg), trans(3, lelg), len1, len2
          real arrayName(len1, len2)
          real tempArray(len1, len2) 
          logical partl
          integer nl, sid, eid
          integer key, nkey, trans_n, nxyz
c         integer atype
          character (len=*), intent(in):: atype 

          starttime = dnekclock()
          trans_n=0
          nxyz = len1
          nl=0
          do i=1, nelt
              trans_n = trans_n +1
              ieg = lglel(i)
              if (gllnid(ieg) .eq. nid) then 
                  trans(1, trans_n) = gllnid(ieg)
                  trans(2, trans_n) = newgllnid(ieg)
                  trans(3, trans_n) = ieg
                  do l=1, nxyz
                     tempArray(l, trans_n) = arrayName(l,i)
                  enddo
              endif
          enddo
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
c            if (atype .eq. 1) then
c               print *, "Component 1b:" , endtime-starttime
c            else
c               print *, "Component 1c:" , endtime-starttime
c            endif 
                print *, "Component 1 " , trim(atype), endtime-starttime
          endif 
c          print *, index_n, trans_n, lelt, nid
           
          starttime = dnekclock()
          key=2
          call crystal_tuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, tempArray,nxyz,key)
c         print *, 'nid: ', nid, 'trans_n', trans_n      
          key=3
          nkey=1
          call crystal_tuple_sort(cr_h, trans_n, trans, 3, 
     $               partl, nl, tempArray, nxyz, key,nkey)
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
             print *, "Component 2 ", trim(atype), endtime-starttime    
          endif

          !Update u
          ! set sid and eid
          starttime = dnekclock()
          !copy tempu to u
              do i=1, trans_n
                  do l=1, nxyz
                     arrayName(l,i) = tempArray(l, i)
                  enddo
              enddo
c      print *, "Update u array: u_n", u_n
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
             print *, "Component 3 ", trim(atype), endtime-starttime  
          endif
       end
c------------------------------------------------------
c subroutine to merge u array
          subroutine mergeUArray_new(newgllnid)
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'CMTDATA'          

          integer newgllnid(lelg), trans(3, lelg)
          real uarray(lx1*ly1*lz1*toteq, lelt) 
c         integer procarray(3, lelg) !keke changed real to integer to use crystal_ituple_transfer
c         real tempu(lx1*ly1*lz1*toteq, lelt)
          logical partl
          integer nl, sid, eid
          integer key, nkey, ifirstelement, ilastelement, u_n, trans_n

          starttime = dnekclock()
          trans_n=0
          nxyz = lx1*ly1*lz1*toteq
          nl=0
          do i=1, nelt
              trans_n = trans_n +1
              ieg = lglel(i)
              if (gllnid(ieg) .eq. nid) then 
c                 procarray(1, trans_n) = gllnid(ieg)
c                 procarray(2, trans_n) = newgllnid(ieg)
c                 procarray(3, trans_n) = ieg
                  trans(1, trans_n) = gllnid(ieg)
                  trans(2, trans_n) = newgllnid(ieg)
                  trans(3, trans_n) = ieg
                  do l=1, toteq
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                                           (l-1)*lz1*ly1*lx1
                                uarray(ind, trans_n) = u(m,n,k,l,i)
                             enddo
                          enddo
                      enddo
                  enddo
              endif
          enddo
c         trans_n=index_n 
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 1b:" , endtime-starttime
          endif 
c          print *, index_n, trans_n, lelt, nid
           
          starttime = dnekclock()
          key=2
          call crystal_tuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, uarray,nxyz,key)
c         print *, 'nid: ', nid, 'trans_n', trans_n      
          key=3
          nkey=1
          call crystal_tuple_sort(cr_h, trans_n, trans, 3, 
     $               partl, nl, uarray, nxyz, key,nkey)
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 2b:" , endtime-starttime
          endif

          !Update u
          ! set sid and eid
          starttime = dnekclock()
          !copy tempu to u
              do i=1, trans_n
                  do l=1, toteq
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                                           (l-1)*lz1*ly1*lx1
                                u(m,n,k,l,i) = uarray(ind, i)
                             enddo
                          enddo
                      enddo
                  enddo
              enddo
c      print *, "Update u array: u_n", u_n
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 3b:" , endtime-starttime
          !print *, "nelgt", nelgt, mod(nid, nelgt/2), nelgt/2-2
          endif
       end
c------------------------------------------------------
c subroutine to merge u array
          subroutine mergeUArray(newgllnid)
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'CMTDATA'          

          integer newgllnid(lelg), trans(3, lelg)
          real uarray(lx1*ly1*lz1*toteq, lelt) 
          integer procarray(3, lelg) !keke changed real to integer to use crystal_ituple_transfer
          real tempu(lx1*ly1*lz1*toteq, lelt)
          logical partl
          integer nl, sid, eid
          integer key, nkey, ifirstelement, ilastelement, u_n, trans_n

          starttime = dnekclock()
          index_n=1
          trans_n=0
          nxyz = lx1*ly1*lz1*toteq
          nl=0
          do i=1, nelt
              ieg = lglel(i)
              if ((gllnid(ieg) .eq. nid) .and. 
     $                     (gllnid(ieg) .ne. newgllnid(ieg))) then
                  procarray(1, index_n) = gllnid(ieg)
                  procarray(2, index_n) = newgllnid(ieg)
                  procarray(3, index_n) = ieg
                  trans(1, index_n) = gllnid(ieg)
                  trans(2, index_n) = newgllnid(ieg)
                  trans(3, index_n) = ieg
                  do l=1, toteq
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                                           (l-1)*lz1*ly1*lx1
                                uarray(ind, index_n) = u(m,n,k,l,i)
                             enddo
                          enddo
                      enddo
                  enddo
              index_n=index_n+1
              endif
          enddo
          index_n=index_n-1
          trans_n=index_n 
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 1b:" , endtime-starttime
          endif 
c          print *, index_n, trans_n, lelt, nid
           
          starttime = dnekclock()
          key=2
          call crystal_tuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, uarray,nxyz,key)
c         print *, 'nid: ', nid, 'trans_n', trans_n      
          key=3
          nkey=1
          call crystal_tuple_sort(cr_h, trans_n, trans, 3, 
     $               partl, nl, uarray, nxyz, key,nkey)
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 2b:" , endtime-starttime
          endif

          !Update u
          ! set sid and eid
          starttime = dnekclock()
          sid=1
          ifirstelement = lglel(sid)
          u_n=0
          do i=1, index_n
              !if (procarray(3,i) .lt. ifirstelement) then
      !            set tempu from uarray
               !    u_n=u_n+1
                !   do j=1, nxyz
                 !     tempu(j,u_n)=uarray(j,i)
                  ! enddo
              if (procarray(3,i) .eq. ifirstelement) then
                       sid=sid+ 1
                       ifirstelement=lglel(sid)
              endif
          enddo
          eid = nelt
          ilastelement = lglel(eid)
          do i=index_n, 1, -1
               if (procarray(3,i) .eq. ilastelement) then
                   eid = eid -1
                   ilastelement = lglel(eid)
               endif
          enddo

          ifirstelement = lglel(sid)
          do i=1, trans_n
              if (trans(3, i) .lt. ifirstelement) then
                  ! set tempu from uarray
                   u_n=u_n+1
                   do j=1, nxyz
                      tempu(j,u_n)=uarray(j,i)
                   enddo
              endif
          enddo

          
          if (sid .le. eid) then
              do i=sid, eid      !set tempu from original u
                  u_n=u_n+1
                  do l=1, toteq
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                                           (l-1)*lz1*ly1*lx1
                                tempu(ind, u_n) = u(m,n,k,l,i)
                             enddo
                          enddo
                      enddo
                  enddo
              enddo 
          endif
          ilastelement = lglel(eid)
          do i=1, trans_n
              if (trans(3, i) .gt. ilastelement) then
                  ! set tempu from uarray
                   u_n=u_n+1
                   do j=1, nxyz
                      tempu(j,u_n)=uarray(j,i)
                   enddo
              endif
          enddo
          !copy tempu to u
              do i=1, u_n
                  do l=1, toteq
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                                           (l-1)*lz1*ly1*lx1
                                u(m,n,k,l,i) = tempu(ind, i)
                             enddo
                          enddo
                      enddo
                  enddo
              enddo
c      print *, "Update u array: u_n", u_n
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 3b:" , endtime-starttime
          !print *, "nelgt", nelgt, mod(nid, nelgt/2), nelgt/2-2
          endif
       end
c----------------------------------------------------------------------
c subroutine to merge phig array
          subroutine mergePhigArray_new(newgllnid)
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'TSTEP'          
          include 'CMTDATA'          

          integer newgllnid(lelg), trans(3, lelg)
          real phigarray(lx1*ly1*lz1, lelt) !keke changed real to integer to use crystal_ituple_transfer
          integer procarray(3, lelg) !keke changed real to integer to use crystal_ituple_transfer
c         real tempphig(lx1*ly1*lz1, lelt)
          logical partl
          integer nl, sid, eid
          integer key, nkey, ifirstelement, ilastelement, phig_n,trans_n

c         Step 1: Build phigarray for the elements to be transferred to neighboring processes.
          starttime = dnekclock()
          trans_n=0;
          nl=0
          nxyz = lx1*ly1*lz1
c         for verification !!!!! 
c         call copy(phig, vx, nxyz*nelt)
c         for verification !!!!! 
          do i=1, nelt
              trans_n=trans_n+1
              ieg = lglel(i)
              if (gllnid(ieg) .eq. nid) then
                  trans(1, trans_n) = gllnid(ieg)
                  trans(2, trans_n) = newgllnid(ieg)
                  trans(3, trans_n) = ieg
                  do k=1, lz1
                      do n=1, ly1
                         do m=1, lx1
                            ind=m+(n-1)*lx1+(k-1)*lx1*ly1 
                            phigarray(ind, trans_n) = phig(m,n,k,i)
                         enddo
                      enddo
                  enddo
              endif
          enddo
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 1a:", endtime - starttime  
          endif 
         
c          print *, index_n, lelg, nid
           
c         Step 2: Send/receive phigarray to/from neighbors
          starttime = dnekclock()
          key=2
          call crystal_tuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, phigarray,nxyz,key)
c         print *, 'nid: ', nid, 'received trans_n', trans_n      
c         Step 2: Sort the received phigarray based on global element number
          key=3
          nkey=1
          call crystal_tuple_sort(cr_h, trans_n, trans, 3, 
     $               partl, nl, phigarray, nxyz, key,nkey)

          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 2a:" , endtime-starttime
          endif
c         Step 4: set start id and end id of phig of existing (not transferred) elements
          !start id is the index of the first element that has not been sent to the left neighbor
          !end id is the index of the last element that has not been sent to the right neighbor
          starttime = dnekclock()
          !copy tempphig to phig
          do i=1, trans_n
             do k=1, lz1
                do n=1, ly1
                    do m=1, lx1
                        ind=m+(n-1)*lx1+(k-1)*lx1*ly1 
                        phig(m,n,k,i) = phigarray(ind, i)
                    enddo
                enddo
             enddo
          enddo
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 3a:", endtime-starttime
          endif
          !if ((istep .eq. 10) .and. (nid .eq. 0)) then
              !OPEN(UNIT=9999,FILE="phig_old_p0.txt",FORM="FORMATTED",
     $         !STATUS="REPLACE",ACTION="WRITE")
          !do i=1, phig_n
             !do k=1, lz1
                !do n=1, ly1
                    !do m=1, lx1
            !WRITE(UNIT=9999, FMT=*) nid, m, n, k, i, phig(m,n,k,i)
                    !enddo
                !enddo
             !enddo
          !enddo
              !CLOSE(UNIT=9999)
          !endif
          !if ((istep .eq. 10) .and. (nid .eq. 1)) then
              !OPEN(UNIT=10000,FILE="phig_old_p1.txt",FORM="FORMATTED",
     $         !STATUS="REPLACE",ACTION="WRITE")
          !do i=1, phig_n
             !do k=1, lz1
                !do n=1, ly1
                    !do m=1, lx1
            !WRITE(UNIT=10000, FMT=*) nid, m, n, k, i, phig(m,n,k,i)
                    !enddo
                !enddo
             !enddo
          !enddo
              !CLOSE(UNIT=10000)
          !endif
c         print *, "Update Phig array: phig_n", phig_n 
          end
c----------------------------------------------------------------------
c subroutine to merge phig array
          subroutine mergePhigArray(newgllnid, trans, trans_n)
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'TSTEP'          
          include 'CMTDATA'          

          integer newgllnid(lelg), trans(3, lelg), trans_n
          real phigarray(lx1*ly1*lz1, lelt) !keke changed real to integer to use crystal_ituple_transfer
          integer procarray(3, lelg) !keke changed real to integer to use crystal_ituple_transfer
          real tempphig(lx1*ly1*lz1, lelt)
          logical partl
          integer nl, sid, eid
          integer key, nkey, ifirstelement, ilastelement, phig_n

c         Step 1: Build phigarray for the elements to be transferred to neighboring processes.
          starttime = dnekclock()
          index_n=1;
          nl=0
          nxyz = lx1*ly1*lz1
c         for verification !!!!! 
c         call copy(phig, vx, nxyz*nelt)
c         for verification !!!!! 
          do i=1, nelt
              ieg = lglel(i)
              if ((gllnid(ieg) .eq. nid) .and. 
     $                     (gllnid(ieg) .ne. newgllnid(ieg))) then
                  procarray(1, index_n) = gllnid(ieg)
                  procarray(2, index_n) = newgllnid(ieg)
                  procarray(3, index_n) = ieg
                  do k=1, lz1
                      do n=1, ly1
                         do m=1, lx1
                            ind=m+(n-1)*lx1+(k-1)*lx1*ly1 
                            phigarray(ind, index_n) = phig(m,n,k,i)
                         enddo
                      enddo
                  enddo
              index_n=index_n+1
              endif
          enddo
          index_n=index_n-1
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 1a:", endtime - starttime  
          endif 
         
c          print *, index_n, lelg, nid
           
c         Step 2: Send/receive phigarray to/from neighbors
          starttime = dnekclock()
          key=2
          call crystal_tuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, phigarray,nxyz,key)
c         print *, 'nid: ', nid, 'received trans_n', trans_n      
c         Step 2: Sort the received phigarray based on global element number
          key=3
          nkey=1
          call crystal_tuple_sort(cr_h, trans_n, trans, 3, 
     $               partl, nl, phigarray, nxyz, key,nkey)

          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 2a:" , endtime-starttime
          endif
c         Step 4: set start id and end id of phig of existing (not transferred) elements
          !start id is the index of the first element that has not been sent to the left neighbor
          !end id is the index of the last element that has not been sent to the right neighbor
          starttime = dnekclock()
          sid=1
          ifirstelement = lglel(sid) 
          phig_n=0
          do i=1, index_n
              !if (procarray(3,i) .lt. ifirstelement) then
      !            set tempphig from phigarray
                   !phig_n=phig_n+1
                   !do j=1, nxyz
                    !  tempphig(j,phig_n)=phigarray(j,i)
                   !enddo
              if (procarray(3,i) .eq. ifirstelement) then
                       sid=sid+ 1
                       ifirstelement=lglel(sid)
              endif
          enddo
          eid = nelt
          ilastelement = lglel(eid)
          do i=index_n, 1, -1
               if (procarray(3,i) .eq. ilastelement) then
                   eid = eid -1
                   ilastelement = lglel(eid)
               endif
          enddo

c         Step 5: Update local phig based on elements 
c                 a) received from left neighbor
c                 b) existing elements
c                 c) received from right neighbor
          ifirstelement = lglel(sid) 
          do i=1, trans_n
              if (trans(3, i) .lt. ifirstelement) then
                  ! set tempphig from phigarray
                   phig_n=phig_n+1
                   do j=1, nxyz
                      tempphig(j,phig_n)=phigarray(j,i)
                   enddo
              endif
          enddo
          
          if (sid .le. eid) then  !set tempphig from original phig
              do i=sid, eid      
                  phig_n=phig_n+1
                  do k=1, lz1
                      do n=1, ly1
                         do m=1, lx1
                            ind=m+(n-1)*lx1+(k-1)*lx1*ly1 
                            tempphig(ind, phig_n) = phig(m,n,k,i)
                         enddo
                      enddo
                  enddo
              enddo 
          endif
          ilastelement = lglel(eid)
          do i=1, trans_n
              if (trans(3, i) .gt. ilastelement) then
                  ! set tempphig from phigarray
                   phig_n=phig_n+1
                   do j=1, nxyz
                      tempphig(j,phig_n)=phigarray(j,i)
                   enddo
              endif
          enddo
          !copy tempphig to phig
          do i=1, phig_n
             do k=1, lz1
                do n=1, ly1
                    do m=1, lx1
                        ind=m+(n-1)*lx1+(k-1)*lx1*ly1 
                        phig(m,n,k,i) = tempphig(ind, i)
                    enddo
                enddo
             enddo
          enddo
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 3a:", endtime-starttime
          endif
          !if ((istep .eq. 10) .and. (nid .eq. 0)) then
              !OPEN(UNIT=9999,FILE="phig_old_p0.txt",FORM="FORMATTED",
     $         !STATUS="REPLACE",ACTION="WRITE")
          !do i=1, phig_n
             !do k=1, lz1
                !do n=1, ly1
                    !do m=1, lx1
            !WRITE(UNIT=9999, FMT=*) nid, m, n, k, i, phig(m,n,k,i)
                    !enddo
                !enddo
             !enddo
          !enddo
              !CLOSE(UNIT=9999)
          !endif
          !if ((istep .eq. 10) .and. (nid .eq. 1)) then
              !OPEN(UNIT=10000,FILE="phig_old_p1.txt",FORM="FORMATTED",
     $         !STATUS="REPLACE",ACTION="WRITE")
          !do i=1, phig_n
             !do k=1, lz1
                !do n=1, ly1
                    !do m=1, lx1
            !WRITE(UNIT=10000, FMT=*) nid, m, n, k, i, phig(m,n,k,i)
                    !enddo
                !enddo
             !enddo
          !enddo
              !CLOSE(UNIT=10000)
          !endif
c         print *, "Update Phig array: phig_n", phig_n 
          end
c----------------------------------------------------------------------
c subroutine to merge CBC arrays
          subroutine mergeCbcArray(newgllnid)
          include 'SIZE'
          include 'INPUT' !cbc is here
          include 'PARALLEL'
          include 'CMTDATA'
c         include 'SOLN'

          integer newgllnid(lelg), trans(3, lelg)
          character*3 tlagarray(6*(ldimt1+1), lelt)
          logical partl
          integer nl, sid, eid
          integer key, nkey, ifirstelement, ilastelement, u_n, trans_n

          starttime = dnekclock()
          trans_n=0
          nxyz = 6*(ldimt1+1)
          nl=0
          do i=1, nelt
              trans_n = trans_n + 1
              ieg = lglel(i)
              if (gllnid(ieg) .eq. nid) then
                  trans(1, trans_n) = gllnid(ieg)
                  trans(2, trans_n) = newgllnid(ieg)
                  trans(3, trans_n) = ieg
                  do l=0, ldimt1
                  do j=1, 6
                      ind=j+l*6
                      tlagarray(ind, trans_n) = cbc(j,i,l)
                  enddo
                  enddo
              endif
          enddo
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 1 cbc:" , endtime-starttime
          endif
c          print *, index_n, trans_n, lelt, nid

          starttime = dnekclock()
          key=2
          call crystal_ctuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, tlagarray,nxyz*3,key)
c         print *, 'nid: ', nid, 'trans_n', trans_n
          key=3
          nkey=1
          call crystal_ctuple_sort(cr_h, trans_n, trans, 3,
     $               partl, nl, tlagarray, nxyz*3, key,nkey)
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 2 cbc:" , endtime-starttime
          endif

          !Update u
          ! set sid and eid
          starttime = dnekclock()
          !copy tempu to u
              do i=1, trans_n
                  do l=0, ldimt1
                  do j=1, 6
                     ind=j+l*6
                     cbc(j,i,l) = tlagarray(ind, i)
                  enddo
                  enddo
              enddo
c      print *, "Update u array: u_n", u_n
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 3 cbc:" , endtime-starttime
          !print *, "nelgt", nelgt, mod(nid, nelgt/2), nelgt/2-2
          endif
       end
c----------------------------------------------------------------------
c subroutine to merge tlag array
          subroutine mergeTlagArray_new(newgllnid)
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'CMTDATA'          
          include 'SOLN'          

          integer newgllnid(lelg), trans(3, lelg)
          real tlagarray(lx1*ly1*lz1*(lorder-1)*ldimt, lelt) 
c         integer procarray(3, lelg) !keke changed real to integer to use crystal_ituple_transfer
c         real temptlag(lx1*ly1*lz1*(lorder-1)*ldimt, lelt)
          logical partl
          integer nl, sid, eid
          integer key, nkey, ifirstelement, ilastelement, u_n, trans_n

          starttime = dnekclock()
          trans_n=0
          nxyz = lx1*ly1*lz1*(lorder-1)*ldimt
          nl=0
          do i=1, nelt
              trans_n = trans_n + 1
              ieg = lglel(i)
              if (gllnid(ieg) .eq. nid) then
c                 procarray(1, index_n) = gllnid(ieg)
c                 procarray(2, index_n) = newgllnid(ieg)
c                 procarray(3, index_n) = ieg
                  trans(1, trans_n) = gllnid(ieg)
                  trans(2, trans_n) = newgllnid(ieg)
                  trans(3, trans_n) = ieg
                  do l=1, ldimt
                  do j=1, lorder-1
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                               (j-1)*lz1*ly1*lx1+
     $                               (l-1)*(lorder-1)*lz1*ly1*lx1 
                             tlagarray(ind, trans_n) = tlag(m,n,k,i,j,l)
                             enddo
                          enddo
                      enddo
                  enddo
                  enddo
              endif
          enddo
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 1a:" , endtime-starttime
          endif 
c          print *, index_n, trans_n, lelt, nid
           
          starttime = dnekclock()
          key=2
          call crystal_tuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, tlagarray,nxyz,key)
c         print *, 'nid: ', nid, 'trans_n', trans_n      
          key=3
          nkey=1
          call crystal_tuple_sort(cr_h, trans_n, trans, 3, 
     $               partl, nl, tlagarray, nxyz, key,nkey)
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 2a:" , endtime-starttime
          endif

          !Update u
          ! set sid and eid
          starttime = dnekclock()
          !copy tempu to u
              do i=1, trans_n
                  do l=1, ldimt
                  do j=1, lorder-1
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                               (j-1)*lz1*ly1*lx1+
     $                               (l-1)*(lorder-1)*lz1*ly1*lx1
                            tlag(m,n,k,i,j,l) = tlagarray(ind, i)
                             enddo
                          enddo
                      enddo
                  enddo
                  enddo
              enddo
c      print *, "Update u array: u_n", u_n
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 3a:" , endtime-starttime
          !print *, "nelgt", nelgt, mod(nid, nelgt/2), nelgt/2-2
          endif
       end
c----------------------------------------------------------------------
c subroutine to merge BC arrays
          subroutine mergeBcArray(newgllnid)
          include 'SIZE'
          include 'INPUT' !bc is here
          include 'PARALLEL'
          include 'CMTDATA'
c         include 'SOLN'

          integer newgllnid(lelg), trans(3, lelg)
          real tlagarray(5*6*(ldimt1+1), lelt)
          logical partl
          integer nl, sid, eid
          integer key, nkey, ifirstelement, ilastelement, u_n, trans_n

          starttime = dnekclock()
          trans_n=0
          nxyz = 5*6*(ldimt1+1)
          nl=0
          do i=1, nelt
              trans_n = trans_n + 1
              ieg = lglel(i)
              if (gllnid(ieg) .eq. nid) then
c                 procarray(1, index_n) = gllnid(ieg)
c                 procarray(2, index_n) = newgllnid(ieg)
c                 procarray(3, index_n) = ieg
                  trans(1, trans_n) = gllnid(ieg)
                  trans(2, trans_n) = newgllnid(ieg)
                  trans(3, trans_n) = ieg
                  do l=0, ldimt1
                  do j=1, 6
                      do k=1, 5
                          ind=k+(j-1)*5+l*6*5
                          tlagarray(ind, trans_n) = bc(k,j,i,l)
                      enddo
                  enddo
                  enddo
              endif
          enddo
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 1 bc " , endtime-starttime
          endif
c          print *, 'index_n', index_n, trans_n, lelt, nid

          starttime = dnekclock()
          key=2
          call crystal_tuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, tlagarray,nxyz,key)
c         print *, 'nid: ', nid, 'trans_n', trans_n
          key=3
          nkey=1
          call crystal_tuple_sort(cr_h, trans_n, trans, 3,
     $               partl, nl, tlagarray, nxyz, key,nkey)
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 2 bc " , endtime-starttime
          endif

          !Update u
          ! set sid and eid
          starttime = dnekclock()
          !copy tempu to u
              do i=1, trans_n
                  do l=0, ldimt1
                  do j=1, 6
                      do k=1, 5
                          ind=k+(j-1)*5+l*6*5
                          bc(k,j,i,l) = tlagarray(ind, i)
                      enddo
                  enddo
                  enddo
              enddo
c      print *, "Update u array: u_n", u_n
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 3 bc " , endtime-starttime
          !print *, "nelgt", nelgt, mod(nid, nelgt/2), nelgt/2-2
          endif
       end
c-------------------------------------------------------------------
c subroutine to merge tlag array
          subroutine mergeTlagArray(newgllnid)
          include 'SIZE'
          include 'INPUT'
          include 'PARALLEL'          
          include 'CMTDATA'          
          include 'SOLN'          

          integer newgllnid(lelg), trans(3, lelg)
          real tlagarray(lx1*ly1*lz1*(lorder-1)*ldimt, lelt) 
          integer procarray(3, lelg) !keke changed real to integer to use crystal_ituple_transfer
          real temptlag(lx1*ly1*lz1*(lorder-1)*ldimt, lelt)
          logical partl
          integer nl, sid, eid
          integer key, nkey, ifirstelement, ilastelement, u_n, trans_n

          starttime = dnekclock()
          index_n=1
          trans_n=0
          nxyz = lx1*ly1*lz1*(lorder-1)*ldimt
          nl=0
          do i=1, nelt
              ieg = lglel(i)
              if ((gllnid(ieg) .eq. nid) .and. 
     $                     (gllnid(ieg) .ne. newgllnid(ieg))) then
                  procarray(1, index_n) = gllnid(ieg)
                  procarray(2, index_n) = newgllnid(ieg)
                  procarray(3, index_n) = ieg
                  trans(1, index_n) = gllnid(ieg)
                  trans(2, index_n) = newgllnid(ieg)
                  trans(3, index_n) = ieg
                  do l=1, ldimt
                  do j=1, lorder-1
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                               (j-1)*lz1*ly1*lx1+
     $                               (l-1)*(lorder-1)*lz1*ly1*lx1 
                             tlagarray(ind, index_n) = tlag(m,n,k,i,j,l)
                             enddo
                          enddo
                      enddo
                  enddo
                  enddo
              index_n=index_n+1
              endif
          enddo
          index_n=index_n-1
          trans_n=index_n 
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 1c:" , endtime-starttime
          endif 
c          print *, index_n, trans_n, lelt, nid
           
          starttime = dnekclock()
          key=2
          call crystal_tuple_transfer(cr_h, trans_n, nelgt, trans,
     $                    3, partl, nl, tlagarray,nxyz,key)
c         print *, 'nid: ', nid, 'trans_n', trans_n      
          key=3
          nkey=1
          call crystal_tuple_sort(cr_h, trans_n, trans, 3, 
     $               partl, nl, tlagarray, nxyz, key,nkey)
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 2c:" , endtime-starttime
          endif

          !Update u
          ! set sid and eid
          starttime = dnekclock()
          sid=1
          ifirstelement = lglel(sid)
          u_n=0
          do i=1, index_n
              !if (procarray(3,i) .lt. ifirstelement) then
      !            set tempu from uarray
               !    u_n=u_n+1
                !   do j=1, nxyz
                 !     tempu(j,u_n)=uarray(j,i)
                  ! enddo
              if (procarray(3,i) .eq. ifirstelement) then
                       sid=sid+ 1
                       ifirstelement=lglel(sid)
              endif
          enddo
          eid = nelt
          ilastelement = lglel(eid)
          do i=index_n, 1, -1
               if (procarray(3,i) .eq. ilastelement) then
                   eid = eid -1
                   ilastelement = lglel(eid)
               endif
          enddo

          ifirstelement = lglel(sid)
          do i=1, trans_n
              if (trans(3, i) .lt. ifirstelement) then
                  ! set tempu from uarray
                   u_n=u_n+1
                   do j=1, nxyz
                      temptlag(j,u_n)=tlagarray(j,i)
                   enddo
              endif
          enddo

          
          if (sid .le. eid) then
              do i=sid, eid      !set tempu from original u
                  u_n=u_n+1
                  do l=1, ldimt
                  do j=1, lorder-1
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                               (j-1)*lz1*ly1*lx1+
     $                               (l-1)*(lorder-1)*lz1*ly1*lx1 
                                temptlag(ind, u_n) = tlag(m,n,k,i,j,l)
                             enddo
                          enddo
                      enddo
                  enddo
                  enddo
              enddo 
          endif
          ilastelement = lglel(eid)
          do i=1, trans_n
              if (trans(3, i) .gt. ilastelement) then
                  ! set tempu from uarray
                   u_n=u_n+1
                   do j=1, nxyz
                      temptlag(j,u_n)=tlagarray(j,i)
                   enddo
              endif
          enddo
          !copy tempu to u
              do i=1, u_n
                  do l=1, ldimt
                  do j=1, lorder-1
                      do k=1, lz1
                          do n=1, ly1
                             do m=1, lx1
                                ind=m+(n-1)*lx1+(k-1)*lx1*ly1+
     $                               (j-1)*lz1*ly1*lx1+
     $                               (l-1)*(lorder-1)*lz1*ly1*lx1
                            tlag(m,n,k,i,j,l) = temptlag(ind, i)
                             enddo
                          enddo
                      enddo
                  enddo
                  enddo
              enddo
c      print *, "Update u array: u_n", u_n
          endtime = dnekclock()
          if( mod(nid, np/2) .eq. np/2-2) then
          print *, "Component 3c:" , endtime-starttime
          !print *, "nelgt", nelgt, mod(nid, nelgt/2), nelgt/2-2
          endif
       end
c----------------------------------------------------------------------
      subroutine reinitialize
      include 'SIZE'
      include 'TOTAL'
      include 'DOMAIN'
      include 'ZPER'
c
      include 'OPCTR'
      include 'CTIMER'
      include 'CMTPART'

      logical ifemati,ifsync_
      common /elementload/ gfirst, inoassignd, resetFindpts, pload(lelg)
      integer gfirst, inoassignd, resetFindpts, pload
      real starttime, endtime

      inoassignd = 0
      call nekgsync()          
      starttime = dnekclock_sync()
      etime = dnekclock_sync()
      call readat_lb
      etims0 = dnekclock_sync()
      if (nio.eq.0) then
         write(6,12) 'called reinitialization'
         write(6,12) 'nelgt/nelgv/lelt:',nelgt,nelgv,lelt
         write(6,12) 'lx1  /lx2  /lx3 :',lx1,lx2,lx3
         write(6,'(A,g13.5,A,/)')' done :: read .rea file ',
     &                             etims0-etime,' sec, readat_lb'
 12      format(1X,A,4I12,/,/)
      endif

      ifsync_ = ifsync
      ifsync = .true.

c     starttime1 = dnekclock_sync() 
c     call setvar          ! Initialize most variables !skip 
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'setvar ', endtime-starttime1 
c     endif 

!#ifdef MOAB
!      if (ifmoab) call nekMOAB_bcs  !   Map BCs
!#endif

      instep=1             ! Check for zero steps
      if (nsteps.eq.0 .and. fintim.eq.0.) instep=0

      igeom = 2
      starttime1 = dnekclock_sync() 
      call setup_topo_lb      ! Setup domain topology  
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'setup_topo_lb ', endtime-starttime1 
      endif 
c     starttime1 = dnekclock_sync() 

c     call genwz           ! Compute GLL points, weights, etc.

c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'genwz ', endtime-starttime1 
c     endif
c     starttime1 = dnekclock_sync() 
c     call io_init         ! Initalize io unit
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'io_init ', endtime-starttime1 
c     endif 
c     starttime1 = dnekclock_sync() 

!      if (ifcvode.and.nsteps.gt.0)
!     $   call cv_setsize(0,nfield) !Set size for CVODE solver

c     if(nio.eq.0) write(6,*) 'call usrdat'
c     call usrdat
c     if(nio.eq.0) write(6,'(A,/)') ' done :: usrdat'
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'usrdat ', endtime-starttime1 
c     endif
      starttime1 = dnekclock_sync() 

      call gengeom(igeom)  ! Generate geometry, after usrdat 
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'gengeom ', endtime-starttime1 
      endif
c     starttime1 = dnekclock_sync() 

      if (ifmvbd) call setup_mesh_dssum ! Set mesh dssum (needs geom)
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'setup_mesh_dssum ', endtime-starttime1 
c     endif
      starttime1 = dnekclock_sync() 

      if(nio.eq.0) write(6,*) 'call usrdat2'
c     call usrdat2_lb
      if(nio.eq.0) write(6,'(A,/)') ' done :: usrdat2'
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'usrdat2_lb ', endtime-starttime1 
      endif

c     starttime1 = dnekclock_sync() 
c     call geom_reset(1)    ! recompute Jacobians, etc.
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'geom_reset ', endtime-starttime1 
c     endif

c     starttime1 = dnekclock_sync() 
c     call vrdsmsh          ! verify mesh topology
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'vrdsmsh ', endtime-starttime1 
c     endif
c     starttime1 = dnekclock_sync() 

!      call echopar ! echo back the parameter stack
c     call setlog  ! Initalize logical flags
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'setlog ', endtime-starttime1 
c     endif

c     starttime1 = dnekclock_sync() 
c     call bcmask  ! Set BC masks for Dirichlet boundaries.
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'bcmash ', endtime-starttime1 
c     endif 
c     starttime1 = dnekclock_sync() 

c     print *, 'fintim', fintim
c     if (fintim.ne.0.0.or.nsteps.ne.0)
c    $   call geneig(igeom) ! eigvals for tolerances
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'geneig ', endtime-starttime1 
c     endif 
c     starttime1 = dnekclock_sync() 

c     call vrdsmsh     !     Verify mesh topology
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'vrdsmsh2 ', endtime-starttime1 
c     endif 

c     starttime1 = dnekclock_sync() 
c     call dg_setup    !     Setup DG, if dg flag is set.
c     endtime = dnekclock_sync()
c     if( mod(nid, np/2) .eq. np/2-2) then
c        print *, 'dg_setup ', endtime-starttime1 
c     endif
      starttime1 = dnekclock_sync() 


!      call init_plugin !     Initialize optional plugin
      if(ifcvode) call cv_setsize


      starttime1 = dnekclock_sync() 
#ifdef CMTNEK
        call nek_cmt_init
        if (nio.eq.0) write(6,*)'Initialized DG machinery'
#endif
      endtime = dnekclock_sync()
      if( mod(nid, np/2) .eq. np/2-2) then
         print *, 'nek_cmt_init ', endtime-starttime1 
      endif

      call nekgsync()          
      endtime = dnekclock()
      if( mod(nid, np/2) .eq. np/2-2) then
          print *, "total reinit time", endtime - starttime
      endif

c     call cmt_switch          ! Check if compiled with cmt
c     if (ifcmt) then          ! Initialize CMT branch
c       call nek_cmt_init
c       if (nio.eq.0) write(6,*)'Initialized DG machinery'
c     endif

c         for verification !!!!! 
c         call outpost(vx, vy, vz, pr, t, 'xyz')
c         call copy(vx, phig, nxyz*nelt)
c         for verification !!!!! 
       !endtime = dnekclock()
       !if( mod(nid, np/2) .eq. np/2-2) then
       !print *, "total reinit time", endtime - starttime
       !endif

       call set_bounds_box
       call update_particle_location   ! move outlier particles
       call move_particles_inproc
      if (red_part .le. 2) call init_interpolation ! barycentric weights for interpolation

      if (two_way.gt.1) then
         call compute_neighbor_el_proc    ! compute list of neigh. el. ranks 
         call create_extra_particles
         call send_ghost_particles
         call spread_props_grid           ! put particle props on grid
      endif
      call interp_props_part_location ! interpolate again for two-way

      return
      end

c------------------------------------------------------------------------
c this function is copyed from David new nek5000 code.
c It is called in the init_stokes_particles
c Sice right now is running David's example 3dbox_back, just rename zufalli and zufall to make them uncalled since they are in the file 3dbox_back
      subroutine zufalli_unused(seed)
      implicit none
c
c  generates initial seed buffer by linear congruential
c  method. Taken from Marsaglia, FSU report FSU-SCRI-87-50
c  variable seed should be 0 < seed <31328
c
      integer seed
      integer ptr
      double precision s,t
      double precision buff(607)
      integer ij,kl,i,ii,j,jj,k,l,m
      common /klotz0/buff,ptr
      data ij/1802/,kl/9373/
c
      if(seed.ne.0) ij = seed
c
      i = mod(ij/177,177) + 2
      j = mod(ij,177) + 2
      k = mod(kl/169,178) + 1
      l = mod(kl,169)
      do 1 ii=1,607
         s = 0.0
         t = 0.5
         do 2 jj=1,24
            m = mod(mod(i*j,179)*k,179)
            i = j
            j = k
            k = m
            l = mod(53*l+1,169)
            if(mod(l*m,64).ge.32) s = s+t
            t = .5*t
2        continue
         buff(ii) = s
1     continue
      
      return 
      end

c------------------------------------------------------------------------


      subroutine zufall_unused(n,a)
      implicit none
c
c portable lagged Fibonacci series uniform random number
c generator with "lags" -273 und -607:
c
c       t    = u(i-273)+buff(i-607)  (floating pt.)
c       u(i) = t - float(int(t))
c
c W.P. Petersen, IPS, ETH Zuerich, 19 Mar. 92
c
      double precision a(*)
      double precision buff(607)
      double precision t
      integer i,k,ptr,VL,k273,k607
      integer buffsz,nn,n,left,q,qq
      integer aptr,aptr0,bptr
c
      common /klotz0/buff,ptr
      data buffsz/607/
c
      aptr = 0
      nn   = n
c
1     continue
c
      if(nn .le. 0) return
c
c factor nn = q*607 + r
c
      q    = (nn-1)/607
      left = buffsz - ptr
c
      if(q .le. 1) then
c
c only one or fewer full segments
c
         if(nn .lt. left) then
            do 2 i=1,nn
               a(i+aptr) = buff(ptr+i)
2           continue
            ptr  = ptr + nn
            return
         else
            do 3 i=1,left
               a(i+aptr) = buff(ptr+i)
3           continue
            ptr  = 0
            aptr = aptr + left
            nn   = nn - left
c  buff -> buff case
            VL   = 273
            k273 = 334
            k607 = 0
            do 4 k=1,3
cdir$ ivdep
*vdir nodep
*VOCL LOOP, TEMP(t), NOVREC(buff)
               do 5 i=1,VL
                  t            = buff(k273+i) + buff(k607+i)
                  buff(k607+i) = t - float(int(t))
5              continue
               k607 = k607 + VL
               k273 = k273 + VL
               VL   = 167
               if(k.eq.1) k273 = 0
4           continue
c
            goto 1
         endif
      else
c
c more than 1 full segment
c
          do 6 i=1,left
             a(i+aptr) = buff(ptr+i)
6         continue
          nn   = nn - left
          ptr  = 0
          aptr = aptr+left
c
c buff -> a(aptr0)
c
          VL   = 273
          k273 = 334
          k607 = 0
          do 7 k=1,3
             if(k.eq.1)then
*VOCL LOOP, TEMP(t)
                do 8 i=1,VL
                   t         = buff(k273+i) + buff(k607+i)
                   a(aptr+i) = t - float(int(t))
8               continue
                k273 = aptr
                k607 = k607 + VL
                aptr = aptr + VL
                VL   = 167
             else
cdir$ ivdep
*vdir nodep
*VOCL LOOP, TEMP(t)
                do 9 i=1,VL
                   t         = a(k273+i) + buff(k607+i)
                   a(aptr+i) = t - float(int(t))
9               continue
                k607 = k607 + VL
                k273 = k273 + VL
                aptr = aptr + VL
             endif
7         continue
          nn = nn - 607
c
c a(aptr-607) -> a(aptr) for last of the q-1 segments
c
          aptr0 = aptr - 607
          VL    = 607
c
*vdir novector
          do 10 qq=1,q-2
             k273 = 334 + aptr0
cdir$ ivdep
*vdir nodep
*VOCL LOOP, TEMP(t), NOVREC(a)
             do 11 i=1,VL
                t         = a(k273+i) + a(aptr0+i)
                a(aptr+i) = t - float(int(t))
11           continue
             nn    = nn - 607
             aptr  = aptr + VL
             aptr0 = aptr0 + VL
10        continue
c
c a(aptr0) -> buff, last segment before residual
c
          VL   = 273
          k273 = 334 + aptr0
          k607 = aptr0
          bptr = 0
          do 12 k=1,3
             if(k.eq.1) then
*VOCL LOOP, TEMP(t)
                do 13 i=1,VL
                   t            = a(k273+i) + a(k607+i)
                   buff(bptr+i) = t - float(int(t))
13              continue
                k273 = 0
                k607 = k607 + VL
                bptr = bptr + VL
                VL   = 167
             else
cdir$ ivdep
*vdir nodep
*VOCL LOOP, TEMP(t), NOVREC(buff)
                do 14 i=1,VL
                   t            = buff(k273+i) + a(k607+i)
                   buff(bptr+i) = t - float(int(t))
14              continue
                k607 = k607 + VL
                k273 = k273 + VL
                bptr = bptr + VL
             endif
12        continue
          goto 1
      endif
      end



c------------------------------------------------------------------------
        subroutine printVerify
            include 'SIZE'
            common /nekmpi/ nid_,np_,nekcomm,nekgroup,nekreal
            
            print *, 'nid: ', nid_, 'nelt: ', nelt
        end




c--------------------------------------------------------------------

c-----------------------------------------------------------------------
      subroutine printTotalHeleq(e, eq)
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'TSTEP'

      real   xerange(2,3,lelt)
      common /elementrange/ xerange

      integer isprint, i, geid, pn, e, eq
      character (len=8):: fmt !format descriptor
      character(5) x1, x2, x3
  
      fmt = '(I4.4)'
      isprint = 0
      geid = e

c     if(istep .eq. 455 .or. istep .eq. 2550) then ! .and. isprint .eq. 1) then
c     if(mod(istep, 500) .eq. 130 .or.mod(istep,500) .eq. 400) then ! .and. isprint .eq. 1) then
      if(istep .ge. 3 .and. istep .le. 7) then ! .and. isprint .eq. 1) then
c     if(istep .eq. 2 .or.istep .eq. 1) then ! .and. isprint .eq. 1) then
      !do geid = 1, nelgt
         do i = 1, nelt
            if(lglel(i) .eq. geid) then !output U array of global element
               isprint = 1              !id = geid
               print *, 'elemt', geid, 'is in proc ', nid, 'local', i
               pn = i
               do j=1, nelt
                  print *, nid,'lglel',j, lglel(j)
               enddo
            endif
         enddo

         if(isprint .eq. 1) then
            write(x1, fmt) geid
            write(x2, fmt) istep
            write(x3, fmt) eq
          OPEN(UNIT=8800+eq+(geid-1)*5,FILE='harreq'//'.'//'id.'
     $        //trim(x1)//'.'
     $        //'step.'//trim(x2)//'.eqn.'//trim(x3),FORM="FORMATTED",
     $        STATUS="REPLACE",ACTION="WRITE")
                do k=1, lz1
                   do n=1, ly1
                       do m=1, lx1
            WRITE(UNIT=8800+eq+(geid-1)*5, FMT=*) m, n, k, eq
                       enddo
                   enddo
                enddo
            CLOSE(UNIT=8800+eq+(geid-1)*5)
            isprint = 0
          endif
        !enddo
        endif
      end


c-----------------------------------------------------------------------
c-----------------------------------------------------------------------
      subroutine printRes1arrayeleq(e, eq)
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'TSTEP'

      real   xerange(2,3,lelt)
      common /elementrange/ xerange

      integer isprint, i, geid, pn, e, eq
      character (len=8):: fmt !format descriptor
      character(5) x1, x2, x3
  
      fmt = '(I4.4)'
      isprint = 0
      geid = e

c     if(istep .eq. 455 .or. istep .eq. 2550) then ! .and. isprint .eq. 1) then
c     if(mod(istep, 500) .eq. 130 .or.mod(istep,500) .eq. 400) then ! .and. isprint .eq. 1) then
      if(istep .ge. 3 .and. istep .le. 7) then ! .and. isprint .eq. 1) then
c     if(istep .eq. 2 .or.istep .eq. 1) then ! .and. isprint .eq. 1) then
      !do geid = 1, nelgt
         do i = 1, nelt
            if(lglel(i) .eq. geid) then !output U array of global element
               isprint = 1              !id = geid
               print *, 'elemt', geid, 'is in proc ', nid, 'local', i
               pn = i
               do j=1, nelt
                  print *, nid,'lglel',j, lglel(j)
               enddo
            endif
         enddo

         if(isprint .eq. 1) then
            write(x1, fmt) geid
            write(x2, fmt) istep
            write(x3, fmt) eq
          OPEN(UNIT=8800+eq+(geid-1)*5,FILE='resarreq'//'.'//'id.'
     $        //trim(x1)//'.'
     $        //'step.'//trim(x2)//'.eqn.'//trim(x3),FORM="FORMATTED",
     $        STATUS="REPLACE",ACTION="WRITE")
                do k=1, lz1
                   do n=1, ly1
                       do m=1, lx1
            WRITE(UNIT=8800+eq+(geid-1)*5, FMT=*) m, n, k, eq, 
     $                 res1(m,n,k,pn,eq)
                       enddo
                   enddo
                enddo
            CLOSE(UNIT=8800+eq+(geid-1)*5)
            isprint = 0
          endif
        !enddo
        endif
      end


c-----------------------------------------------------------------------
      subroutine printRes1arrayel(e)
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'TSTEP'

      real   xerange(2,3,lelt)
      common /elementrange/ xerange

      integer isprint, i, geid, pn, e
      character (len=8):: fmt !format descriptor
      character(5) x1, x2
  
      fmt = '(I4.4)'
      isprint = 0
      geid = e

c     if(istep .eq. 455 .or. istep .eq. 2550) then ! .and. isprint .eq. 1) then
c     if(mod(istep, 500) .eq. 130 .or.mod(istep,500) .eq. 400) then ! .and. isprint .eq. 1) then
      if(istep .ge. 3 .and. istep .le. 7) then ! .and. isprint .eq. 1) then
c     if(istep .eq. 2 .or.istep .eq. 1) then ! .and. isprint .eq. 1) then
      !do geid = 1, nelgt
         do i = 1, nelt
            if(lglel(i) .eq. geid) then !output U array of global element
               isprint = 1              !id = geid
               print *, 'elemt', geid, 'is in proc ', nid, 'local', i
               pn = i
               do j=1, nelt
                  print *, nid,'lglel',j, lglel(j)
               enddo
            endif
         enddo

         if(isprint .eq. 1) then
            write(x1, fmt) geid
            write(x2, fmt) istep
          OPEN(UNIT=9000+geid,FILE='resarray'//'.'//'id.'//trim(x1)//'.'
     $        //'step.'//trim(x2),FORM="FORMATTED",
     $        STATUS="REPLACE",ACTION="WRITE")
              do i=1, toteq
                do k=1, lz1
                   do n=1, ly1
                       do m=1, lx1
            WRITE(UNIT=9000+geid, FMT=*) m, n, k, i, res1(m,n,k,pn,i)
                       enddo
                   enddo
                enddo
             enddo
            CLOSE(UNIT=9000+geid)
            isprint = 0
          endif
        !enddo
        endif
      end


c-----------------------------------------------------------------------
      subroutine printRes1array
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'TSTEP'

      real   xerange(2,3,lelt)
      common /elementrange/ xerange

      integer isprint, i, geid, pn
      character (len=8):: fmt !format descriptor
      character(5) x1, x2
  
      fmt = '(I4.4)'
      isprint = 0
      geid = 1

c     if(istep .eq. 455 .or. istep .eq. 2550) then ! .and. isprint .eq. 1) then
c     if(mod(istep, 500) .eq. 130 .or.mod(istep,500) .eq. 400) then ! .and. isprint .eq. 1) then
      if(istep .ge. 2500 .and. istep .le. 2600) then ! .and. isprint .eq. 1) then
c     if(istep .eq. 2 .or.istep .eq. 1) then ! .and. isprint .eq. 1) then
      do geid = 1, nelgt
         do i = 1, nelt
            if(lglel(i) .eq. geid) then !output U array of global element
               isprint = 1              !id = geid
               print *, 'elemt', geid, 'is in proc ', nid, 'local', i
               pn = i
               do j=1, nelt
                  print *, nid,'lglel',j, lglel(j)
               enddo
            endif
         enddo

         if(isprint .eq. 1) then
            write(x1, fmt) geid
            write(x2, fmt) istep
          OPEN(UNIT=9000+geid,FILE='resarray'//'.'//'id.'//trim(x1)//'.'
     $        //'step.'//trim(x2),FORM="FORMATTED",
     $        STATUS="REPLACE",ACTION="WRITE")
              do i=1, toteq
                do k=1, lz1
                   do n=1, ly1
                       do m=1, lx1
            WRITE(UNIT=9000+geid, FMT=*) m, n, k, i, res1(m,n,k,pn,i)
                       enddo
                   enddo
                enddo
             enddo
            CLOSE(UNIT=9000+geid)
            isprint = 0
          endif
        enddo
        endif
      end


c-----------------------------------------------------------------------
      subroutine printGraduarray(e)
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'TSTEP'
      include 'GEOM'

      real   xerange(2,3,lelt)
      common /elementrange/ xerange

      integer isprint, i, geid, pn, ind, e
      character (len=8):: fmt !format descriptor
      character(5) x1, x2
  
      fmt = '(I4.4)'
      isprint = 0
      geid = e

c     if(istep .eq. 455 .or. istep .eq. 2550) then ! .and. isprint .eq. 1) then
c     if(mod(istep, 500) .eq. 130 .or.mod(istep,500) .eq. 400) then ! .and. isprint .eq. 1) then
      if(istep .ge. 3 .and. istep .le. 7) then ! .and. isprint .eq. 1) then
c     if(istep .eq. 2 .or.istep .eq. 1) then ! .and. isprint .eq. 1) then
      !do geid = 1, nelgt
         do i = 1, nelt
            if(lglel(i) .eq. geid) then !output U array of global element
               isprint = 1              !id = geid
               print *, 'elemt', geid, 'is in proc ', nid, 'local', i
               pn = i
               do j=1, nelt
                  print *, nid,'lglel',j, lglel(j)
               enddo
            endif
         enddo

         if(isprint .eq. 1) then
            write(x1, fmt) geid
            write(x2, fmt) istep
          OPEN(UNIT=9200+geid,FILE='grarray'//'.'//'id.'//trim(x1)//'.'
     $        //'step.'//trim(x2),FORM="FORMATTED",
     $        STATUS="REPLACE",ACTION="WRITE")
              do i=1, toteq
                do k=1, lz1
                   do n=1, ly1
                       do m=1, lx1
                          ind = m + (n-1)*lx1 + (k-1)*lx1*ly1
            WRITE(UNIT=9200+geid, FMT=*) gradu(ind,i,1), gradu(ind,i,2),
     $                          gradu(ind,i,3)
                       enddo
                   enddo
                enddo
              enddo
            CLOSE(UNIT=9200+geid)
            isprint = 0
          endif
        !enddo
        endif
      end


c-----------------------------------------------------------------------
c-----------------------------------------------------------------------
      subroutine printJacmiarray
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'TSTEP'
      include 'GEOM'

      real   xerange(2,3,lelt)
      common /elementrange/ xerange

      integer isprint, i, geid, pn, ind
      character (len=8):: fmt !format descriptor
      character(5) x1, x2
  
      fmt = '(I4.4)'
      isprint = 0
      geid = 1

c     if(istep .eq. 455 .or. istep .eq. 2550) then ! .and. isprint .eq. 1) then
c     if(mod(istep, 500) .eq. 130 .or.mod(istep,500) .eq. 400) then ! .and. isprint .eq. 1) then
      if(istep .ge. 3 .and. istep .le. 7) then ! .and. isprint .eq. 1) then
c     if(istep .eq. 2 .or.istep .eq. 1) then ! .and. isprint .eq. 1) then
      do geid = 1, nelgt
         do i = 1, nelt
            if(lglel(i) .eq. geid) then !output U array of global element
               isprint = 1              !id = geid
               print *, 'elemt', geid, 'is in proc ', nid, 'local', i
               pn = i
               do j=1, nelt
                  print *, nid,'lglel',j, lglel(j)
               enddo
            endif
         enddo

         if(isprint .eq. 1) then
            write(x1, fmt) geid
            write(x2, fmt) istep
          OPEN(UNIT=9100+geid,FILE='jacarray'//'.'//'id.'//trim(x1)//'.'
     $        //'step.'//trim(x2),FORM="FORMATTED",
     $        STATUS="REPLACE",ACTION="WRITE")
                do k=1, lz1
                   do n=1, ly1
                       do m=1, lx1
                          ind = m + (n-1)*lx1 + (k-1)*lx1*ly1
            WRITE(UNIT=9100+geid, FMT=*) m, n, k, jacmi(ind,pn)
                       enddo
                   enddo
                enddo
            CLOSE(UNIT=9100+geid)
            isprint = 0
          endif
        enddo
        endif
      end


c-----------------------------------------------------------------------
      subroutine printUarray
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'TSTEP'

      real   xerange(2,3,lelt)
      common /elementrange/ xerange

      integer isprint, i, geid, pn
      character (len=8):: fmt !format descriptor
      character(5) x1, x2
  
      fmt = '(I4.4)'
      isprint = 0
      geid = 1

c     if(istep .eq. 455 .or. istep .eq. 2550) then ! .and. isprint .eq. 1) then
c     if(mod(istep, 500) .eq. 130 .or.mod(istep,500) .eq. 400) then ! .and. isprint .eq. 1) then
      if((istep .ge. 1990 .and. istep .le. 2010)
     $      .or.(istep .ge. 2490 .and. istep .le. 2510)
     $      .or.(istep .ge.2990)) then ! .and. isprint .eq. 1) then
c     if(istep .eq. 2 .or.istep .eq. 1) then ! .and. isprint .eq. 1) then
      do geid = 1, nelgt
         do i = 1, nelt
            if(lglel(i) .eq. geid) then !output U array of global element
               isprint = 1              !id = geid
               print *, 'elemt', geid, 'is in proc ', nid, 'local', i
               pn = i
               do j=1, nelt
                  print *, nid,'lglel',j, lglel(j)
               enddo
            endif
         enddo

         if(isprint .eq. 1) then
            print *, "writing uarray file, istep",istep, 
     >         "id", geid, "location:"
     >     , xerange(1,1,pn), xerange(2,1,pn), xerange(1,2,pn)
     >     , xerange(2,2,pn), xerange(1,3,pn), xerange(2,3,pn)
c    >     , "element", geid, "is in proc", nid, "local", pn

            write(x1, fmt) geid
            write(x2, fmt) istep
          OPEN(UNIT=9999+geid,FILE='uarray'//'.'//'id.'//trim(x1)//'.'
     $        //'step.'//trim(x2),FORM="FORMATTED",
     $        STATUS="REPLACE",ACTION="WRITE")
              do i=1, toteq
                do k=1, lz1
                   do n=1, ly1
                       do m=1, lx1
            WRITE(UNIT=9999+geid, FMT=*) m, n, k, i, u(m,n,k,i,pn)
                       enddo
                   enddo
                enddo
             enddo
            CLOSE(UNIT=9999+geid)
            isprint = 0
          endif
        enddo
        endif
      end


c-----------------------------------------------------------------------
      subroutine printUarray2
      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'TSTEP'

c     integer stage
      integer isprint, i, geid, pn
      character (len=8):: fmt !format descriptor
      character(5) x1, x2, x3
  
      fmt = '(I4.4)'
      isprint = 0
      geid = 1

c     if(istep .eq. 455 .or. istep .eq. 2550) then ! .and. isprint .eq. 1) then
c     if(mod(istep, 500) .eq. 130 .or.mod(istep,500) .eq. 400) then ! .and. isprint .eq. 1) then
c     if(istep .gt. 500 .and. istep .lt. 630) then ! .and. isprint .eq. 1) then
      if(istep .eq. 502 .or.istep .eq. 501) then ! .and. isprint .eq. 1) then
         do i = 1, nelt
            if(lglel(i) .eq. geid) then !output U array of global element
               isprint = 1              !id = geid
               print *, 'elemt', geid, 'is in proc ', nid, 'local', i
               pn = i
               do j=1, nelt
                  print *, nid,'lglel',j, lglel(j)
               enddo
            endif
         enddo

         if(isprint .eq. 1) then
            print *, "writing uarray file"

            write(x1, fmt) geid
            write(x2, fmt) istep
            write(x3, fmt) stage
          OPEN(UNIT=9999,FILE='uarray'//'.'//'id.'//trim(x1)//'.'
     $        //'step.'//trim(x2)//'stage.'//trim(x3),FORM="FORMATTED",
     $        STATUS="REPLACE",ACTION="WRITE")
              do i=1, toteq
                do k=1, lz1
                   do n=1, ly1
                       do m=1, lx1
            WRITE(UNIT=9999, FMT=*) m, n, k, i, u(m,n,k,i,pn)
                       enddo
                   enddo
                enddo
             enddo
            CLOSE(UNIT=9999)
          endif
        endif
      end
