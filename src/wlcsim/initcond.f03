#include "../defines.inc"
!! ---------------------------------------------------------------*

!
!     This subroutine sets the initial condition for a chain within
!     the capsid
!
!     Andrew Spakowitz
!     Written 4-16-04
!
!     Updated by Quinn in 2016
!
subroutine initcond(wlc_d,R,U,NT,NB,NP,FRMFILE,PARA, &
                    rand_stat, wlc_p)

!use mt19937, only : grnd, init_genrand, rnorm, mt, mti
use mersenne_twister
use params, only: dp, pi, wlcsim_params, wlcsim_data, nan
use vector_utils, only: randomUnitVec, random_perp
implicit none

Type(wlcsim_data), intent(inout) :: wlc_d     ! system allocated data
type(wlcsim_params), intent(in) :: wlc_p

integer NB,NP,NT           ! Number of beads
real(dp) R(3,NT)  ! Bead positions
real(dp) U(3,NT)  ! Tangent vectors
real(dp) GAM      ! Equil bead separation
real(dp) LBOX(3)  ! Box edge length
integer I,J,IB            ! Index Holders
LOGICAL FRMFILE           ! Is conformation in file?
!real(dp) RMin
real(dp) R0(3)
real(dp) PARA(10)

!     Varibles for type 2

real(dp) Uold(3) ! save previous direction
real(dp) Rold(3) ! save previous position
real(dp) theta   ! random angle
real(dp) z       ! random z position
real(dp) rr      ! random radial position
LOGICAL search           ! for exiting while loop
real(dp) test(3) ! test position for inside confinment
real(dp) Rc      ! radius of confinement
integer ii !for testing

!   temporary variables
real(dp) mag    ! magnitude of U for reload, or of U when smoothing

!      Random number generator initiation
type(random_stat) rand_stat
real urand(3)
logical in_confinement

real(dp) center(3)
real(dp) RloopVec(3)
real(dp) perpVec(3)
real(dp) trash(3)
real(dp) length
integer otherEnd
real(dp) nloops

LBOX(1)=WLC_P__LBOX_X
LBOX(2)=WLC_P__LBOX_Y
LBOX(3)=WLC_P__LBOX_Z

GAM = PARA(4)

!     Setup the choice parameters

if (FRMFILE)then
   open (UNIT = 5, FILE = 'input/r0', STATUS = 'OLD')
   Do I = 1,NT
      READ(5,*) R(1,I),R(2,I),R(3,I)
   enddo
   CLOSE(5)

   open (UNIT = 5, FILE = 'input/u0', STATUS = 'OLD')
   Do I = 1,NT
      READ(5,*) U(1,I),U(2,I),U(3,I)
       mag = sqrt(U(1,I)**2 + U(2,I)**2 + U(3,I)**2)
       U(1,I) = U(1,I)/mag
       U(2,I) = U(2,I)/mag
       U(3,I) = U(3,I)/mag
   enddo

   CLOSE(5)
   return
endif
!     Fix the initial condition
if (WLC_P__INITCONDTYPE.eq.'lineInYFromOrigin') then
! straight line in y direction starting at origin, equilibrium bond lengths
    iB = 1
    do i = 1,nP
        do j = 1,nB
            R(1,iB) = 0.0_dp
            R(2,iB) = gam*j
            R(3,iB) = 0.0_dp
            U(1,iB) = 0.0_dp
            U(2,iB) = 1.0_dp
            U(3,iB) = 0.0_dp
            iB = iB + 1
        enddo
    enddo

else if (WLC_P__INITCONDTYPE.eq.'lineInY') then
! staight line in y direction with random starting position

    IB = 1
    do I = 1,NP
       call random_number(urand,rand_stat)
       R0(1) = urand(1)*LBOX(1)
       R0(2) = urand(2)*LBOX(2)
       R0(3) = urand(3)*LBOX(3)

       do J = 1,NB
          R(1,IB) = R0(1)
          R(2,IB) = R0(2) + GAM*(J - NB/2.0_dp - 0.5_dp) ! center on box
          R(3,IB) = R0(3)
          U(1,IB) = 0.0_dp
          U(2,IB) = 1.0_dp
          U(3,IB) = 0.0_dp
          IB = IB + 1

       enddo
    enddo

else if (WLC_P__INITCONDTYPE.eq.'randomLineSlitInZBoundary') then
    ! travel in radom direction
    ! rerandomize when reaching boundary
    ! slit boundary in z direction

    IB = 1
    do  I = 1,NP
        call random_number(urand,rand_stat)
        Rold(1) = urand(1)*LBOX(1)
        Rold(2) = urand(2)*LBOX(2)
        Rold(3) = urand(3)*LBOX(3)
        call randomUnitVec(Uold,rand_stat)

        do J = 1,NB
           search = .TRUE.
           ii = 0
           do while(search)
                ii = ii + 1
                if (ii.gt.100) then
                    print*,'stuck in loop'
                    print*,'Rold = ',Rold(1),Rold(2),Rold(3)
                    print*,'test = ',test(1),test(2),test(3)
                    exit
                endif
                test(1) = Rold(1) + Uold(1)*GAM
                test(2) = Rold(2) + Uold(2)*GAM
                test(3) = Rold(3) + Uold(3)*GAM
                search = .not. in_confinement(test, 1, 1, 1)
                if (search) then
                     call randomUnitVec(Uold,rand_stat)
                endif
           enddo
           R(1,IB) = test(1)
           R(2,IB) = test(2)
           R(3,IB) = test(3)
           Rold(1) = test(1)
           Rold(2) = test(2)
           Rold(3) = test(3)
           U(1,IB) = Uold(1)
           U(2,IB) = Uold(2)
           U(3,IB) = Uold(3)

           IB = IB + 1
        enddo
    enddo
else if (WLC_P__INITCONDTYPE.eq.'randomLineCubeBoundary') then
    ! travel in radom direction
    ! rerandomize when reaching boundary
    ! square boundary

    IB = 1
    do  I = 1,NP
       call random_number(urand,rand_stat)
       Rold(1) = urand(1)*LBOX(1)
       Rold(2) = urand(2)*LBOX(2)
       Rold(3) = urand(3)*LBOX(3)
       call randomUnitVec(Uold,rand_stat)

       do J = 1,NB
          search = .TRUE.
          ii = 0
          do while(search)
               ii = ii + 1
               if (ii.gt.100) then
                   print*,'stuck in loop'
                   print*,'Rold = ',Rold(1),Rold(2),Rold(3)
                   print*,'test = ',test(1),test(2),test(3)
                   exit
               endif
               test(1) = Rold(1) + Uold(1)*GAM
               test(2) = Rold(2) + Uold(2)*GAM
               test(3) = Rold(3) + Uold(3)*GAM
               search = .not. in_confinement(test, 1, 1, 1)
               if (search) then
                    call randomUnitVec(Uold,rand_stat)
               endif
          enddo
          R(1,IB) = test(1)
          R(2,IB) = test(2)
          R(3,IB) = test(3)
          Rold(1) = test(1)
          Rold(2) = test(2)
          Rold(3) = test(3)
          U(1,IB) = Uold(1)
          U(2,IB) = Uold(2)
          U(3,IB) = Uold(3)

          IB = IB + 1
       enddo
    enddo

else if (WLC_P__INITCONDTYPE.eq.'randomLineOutsideOfSphere') then
    ! travel in radom direction
    ! rerandomize when reaching boundary
    ! internalshpere boundary
    Rc = WLC_P__CONFINEMENT_SPHERE_DIAMETER/2.0_dp ! use LBOX as radius
    IB = 1
    do  I = 1,NP
       search = .TRUE.
       do while(search)
           call random_number(urand,rand_stat)
           Rold(1) = urand(1)*LBOX(1)
           Rold(2) = urand(2)*LBOX(2)
           Rold(3) = urand(3)*LBOX(3)
           search = .not. in_confinement(Rold, 1, 1, 1)
       enddo
       call randomUnitVec(Uold,rand_stat)
       do J = 1,NB
           search = .TRUE.
           ii=0
           do while(search)
               test(1) = Rold(1) + Uold(1)*GAM
               test(2) = Rold(2) + Uold(2)*GAM
               test(3) = Rold(3) + Uold(3)*GAM
               search = .not. in_confinement(test, 1, 1, 1)
               if (search) then
                    ii = ii + 1
                    if (ii.gt.100) then
                        print*,'stuck in loop'
                        print*,'Rold = ',Rold(1),Rold(2),Rold(3)
                        print*,'test = ',test(1),test(2),test(3)
                        print*,'diameter',WLC_P__CONFINEMENT_SPHERE_DIAMETER
                        print*,'center',WLC_P__LBOX_X/2.0_dp,&
                                        WLC_P__LBOX_Y/2.0_dp,&
                                        WLC_P__LBOX_Z/2.0_dp
                        stop
                    endif
                    call randomUnitVec(Uold,rand_stat)
               endif
           enddo
           R(1,IB) = test(1)
           R(2,IB) = test(2)
           R(3,IB) = test(3)
           Rold(1) = test(1)
           Rold(2) = test(2)
           Rold(3) = test(3)
           U(1,IB) = Uold(1)
           U(2,IB) = Uold(2)
           U(3,IB) = Uold(3)
           IB = IB + 1
       enddo ! loop to N
    enddo ! loop to np
else if (WLC_P__INITCONDTYPE.eq.'randomLineSphereBoundary') then
    ! travel in radom direction
    ! rerandomize when reaching boundary
    ! shpere boundary
    ! radius of LBox/2 centered at LBox/2
    Rc = WLC_P__CONFINEMENT_SPHERE_DIAMETER/2.0_dp ! use LBOX as radius
    IB = 1
    do  I = 1,NP
       call random_number(urand,rand_stat)
       theta = urand(1)*2.0_dp*PI
       z = urand(2)*2.0_dp-1.0_dp
       rr = Rc*urand(3)  ! should have an r**2 from jacobian
       Rold(1) = sqrt(1.0_dp-z*z)*cos(theta)*rr + WLC_P__LBOX_X/2.0_dp
       Rold(2) = sqrt(1.0_dp-z*z)*sin(theta)*rr + WLC_P__LBOX_Y/2.0_dp
       Rold(3) = z*rr + WLC_P__LBOX_Z/2.0_dp
       call randomUnitVec(Uold,rand_stat)
       do J = 1,NB
           search = .TRUE.
           ii=0
           do while(search)
               test(1) = Rold(1) + Uold(1)*GAM
               test(2) = Rold(2) + Uold(2)*GAM
               test(3) = Rold(3) + Uold(3)*GAM
               search = .not. in_confinement(test, 1, 1, 1)
               if (search) then
                    ii = ii + 1
                    if (ii.gt.100) then
                        print*,'stuck in loop'
                        print*,'Rold = ',Rold(1),Rold(2),Rold(3)
                        print*,'test = ',test(1),test(2),test(3)
                        print*,'diameter',WLC_P__CONFINEMENT_SPHERE_DIAMETER
                        print*,'center',WLC_P__LBOX_X/2.0_dp,&
                                        WLC_P__LBOX_Y/2.0_dp,&
                                        WLC_P__LBOX_Z/2.0_dp
                        stop
                    endif
                    call randomUnitVec(Uold,rand_stat)
               endif
           enddo
           R(1,IB) = test(1)
           R(2,IB) = test(2)
           R(3,IB) = test(3)
           Rold(1) = test(1)
           Rold(2) = test(2)
           Rold(3) = test(3)
           U(1,IB) = Uold(1)
           U(2,IB) = Uold(2)
           U(3,IB) = Uold(3)
           IB = IB + 1
       enddo ! loop to N
    enddo ! loop to np
else if (WLC_P__INITCONDTYPE.eq.'randomlyDistributeBeadsInSphere') then
    ! randomly distribute beads in shereical confinement
    do IB = 1,NT
        search = .true.
        do while(search)
             call random_number(urand,rand_stat)
             test(1) = urand(1)*LBox(1)
             test(2) = urand(2)*LBox(2)
             test(3) = urand(3)*LBox(3)
             search = .not. in_confinement(test, 1, 1, 1)
        enddo
        R(1,IB) = test(1)
        R(2,IB) = test(2)
        R(3,IB) = test(3)
        U(1,IB) = 0.00_dp
        U(2,IB) = 0.00_dp
        U(3,IB) = 0.00_dp
    enddo
else if (WLC_P__INITCONDTYPE == 'ring') then
    IB = 1
    do  I = 1,NP
        call random_number(urand,rand_stat)
        R0(1) = urand(1)*LBOX(1)
        R0(2) = urand(2)*LBOX(1)
        R0(3) = urand(3)*LBOX(1)
        do  J = 1,NB
             R(1,IB) = R0(1) + ((GAM*NB)/(2*PI))*Cos(J*2.0_dp*PI/NB)
             R(2,IB) = R0(2) + ((GAM*NB)/(2*PI))*Sin(J*2.0_dp*PI/NB)
             R(3,IB) = 0.0_dp
             U(1,IB) = -Sin(J*2.0_dp*PI/NB)
             U(2,IB) = Cos(J*2.0_dp*PI/NB)
             U(3,IB) = 0.0_dp;
             IB = IB + 1
        ENDdo
    ENDdo
elseif (WLC_P__INITCONDTYPE == 'multiRing') then
    IB = 1
    center(1) = WLC_P__LBOX_X/2.0_dp
    center(2) = WLC_P__LBOX_X/2.0_dp
    center(3) = WLC_P__LBOX_X/2.0_dp
    do while (IB .le. WLC_P__NT)
        if (IB == WLC_P__NT) then
            R(:,IB) = center
            call randomUnitVec(RloopVec,rand_stat)
            U(:,IB) = RloopVec
            exit
        endif
        otherEnd = IB+1
        do
            if (otherEnd == WLC_P__NT) exit
            if (wlc_d%ExplicitBindingPair(otherEnd) /= -1) exit
            otherEnd=otherEnd+1
        enddo

        call randomUnitVec(RloopVec,rand_stat)
        if (otherEnd == IB) then
            R(:,I) = center
            U(:,I) = RloopVec
        endif
        call random_perp(RloopVec,perpVec,trash,rand_stat)

        length = ((otherEnd-IB)*GAM/(2.0_dp*PI))
        nloops = ceiling(length/(WLC_P__CONFINEMENT_SPHERE_DIAMETER*0.25_dp))
        length = length/nloops

        do I = IB,otherEnd
            R(:,I) = center + length*( &
                     + cos(2.0_dp*PI*nloops*(I-IB)/real(otherEnd-IB))*RloopVec &
                     + sin(2.0_dp*PI*nloops*(I-IB)/real(otherEnd-IB))*perpVec &
                     - RloopVec)
            U(:,I) = cos(2.0_dp*PI*nloops*(I-IB)/real(otherEnd-IB))*perpVec &
                    -sin(2.0_dp*PI*nloops*(I-IB)/real(otherEnd-IB))*RloopVec
        enddo
        IB=otherEnd+1
    enddo


else if (WLC_P__INITCONDTYPE == 'WormlikeChain') then
    call effective_wormlike_chain_init(R, U, NT, wlc_p, rand_stat)
else if (WLC_P__INITCONDTYPE == 'randomWalkWithBoundary') then
    call gaus_init(R, U, NT, wlc_p, rand_stat)
else
    print*, "Unknown version of chain initialization WLC_P__INITCONDTYPE....."
    stop 1
endif

RETURN
END

subroutine wlc_init(R, U, NB, EPS, l0, rand_stat)
        ! takes R(3,NB) with R(:,1) preset and makes a WLC given EPS
    use mersenne_twister, only : random_number, random_stat
    use params, only : dp, pi

    implicit none

    integer, intent(in) :: NB
    real(dp), intent(in) :: EPS, l0
    real(dp), intent(inout) :: R(3,NB), U(3,NB)
    type(random_stat), intent(inout) :: rand_stat

    integer J
    real(dp) N1(3), N2(3), z, theta
    real urand(3)

    do J = 2,NB
         call random_number(urand,rand_stat)
         theta = urand(1)*2.0_dp*pi
         z = (1.0_dp/EPS)*log(2.0_dp*sinh(EPS)*urand(2)+exp(-EPS))
         N1(1) = 0.0_dp
         N1(2) = 0.0_dp
         N1(3) = 1.0_dp
         N1(1) = N1(1)-(N1(1)*U(1,J-1)+N1(2)*U(2,J-1)+N1(3)*U(3,J-1))*U(1,J-1)
         N1(2) = N1(2)-(N1(1)*U(1,J-1)+N1(2)*U(2,J-1)+N1(3)*U(3,J-1))*U(2,J-1)
         N1(3) = N1(3)-(N1(1)*U(1,J-1)+N1(2)*U(2,J-1)+N1(3)*U(3,J-1))*U(3,J-1)
         N1 = N1/norm2(N1)

         N2(1) = N1(2)*U(3,J-1)-N1(3)*U(2,J-1)
         N2(2) = N1(3)*U(1,J-1)-N1(1)*U(3,J-1)
         N2(3) = N1(1)*U(2,J-1)-N1(2)*U(1,J-1)
         N2 = N2/norm2(N2)

         U(1,J) = sqrt(1-z*z)*cos(theta)*N1(1)+sqrt(1-z*z)*sin(theta)*N2(1)+z*U(1,J-1)
         U(2,J) = sqrt(1-z*z)*cos(theta)*N1(2)+sqrt(1-z*z)*sin(theta)*N2(2)+z*U(2,J-1)
         U(3,J) = sqrt(1-z*z)*cos(theta)*N1(3)+sqrt(1-z*z)*sin(theta)*N2(3)+z*U(3,J-1)
         U(:,J) = U(:,J)/norm2(U(:,J))

         R(1,J) = R(1,J-1) + l0*U(1,J)
         R(2,J) = R(2,J-1) + l0*U(2,J)
         R(3,J) = R(3,J-1) + l0*U(3,J)
     enddo
end subroutine wlc_init

subroutine effective_wormlike_chain_init(R, U, NT, wlc_p, rand_stat)
    use mersenne_twister
    use params, only : wlcsim_params, dp, max_wlc_l0, max_sswlc_delta
    use vector_utils, only: randomUnitVec
    implicit none
    integer, intent(in) :: nt
    type(wlcsim_params), intent(in) :: wlc_p
    real(dp), intent(out) :: R(3,nt), U(3,nt)
    type(random_stat), intent(inout) :: rand_stat

    integer IB, NgB, i, j
    real(dp) l0, eps
    real urand(3)
    real(dp), dimension(:,:), allocatable :: tmpR, tmpU

    if (max_sswlc_delta < wlc_p%DEL) then
        print *, "You can use gaussian chain-based initialization since your beads are so far apart, stopping..."
        stop 1
    end if
    IB = 1
    if (wlc_p%DEL > max_wlc_l0) then
        NgB = ceiling(wlc_p%DEL/max_wlc_l0) + 1
    else
        NgB = 1 + 1
    endif
    allocate(tmpR(3,NgB))
    allocate(tmpU(3,NgB))
    l0 = wlc_p%DEL/(NgB - 1)
    EPS = WLC_P__LP/l0 ! bending rigidity for wormlike chain
    do I = 1,WLC_P__NP
        ! uniformly first bead inside box
        call random_number(urand,rand_stat)
        R(1,IB) = urand(1)*WLC_P__LBOX_X
        R(2,IB) = urand(2)*WLC_P__LBOX_Y
        R(3,IB) = urand(3)*WLC_P__LBOX_Z
        ! uniformly from unit sphere first tan vec
        call randomUnitVec(U(:,IB),rand_stat)
        IB = IB + 1
        do J = 2,WLC_P__NB
            tmpR(:,1) = R(:,IB-1)
            tmpU(:,1) = U(:,IB-1)
            call wlc_init(tmpR, tmpU, NgB, EPS, l0, rand_stat)
            R(:,IB) = tmpR(:,NgB)
            U(:,IB) = tmpU(:,NgB)
            IB = IB + 1
        enddo
    enddo
    deallocate(tmpR)
    deallocate(tmpU)
end subroutine effective_wormlike_chain_init

subroutine gaus_init(R, U, NT, wlc_p, rand_stat)
    use mersenne_twister
    use params
    implicit none
    integer, intent(in) :: NT
    type(wlcsim_params), intent(in) :: wlc_p
    real(dp), intent(out) :: R(3,NT), U(3,NT)
    type(random_stat), intent(inout) :: rand_stat
    real urand(3)
    real(dp) :: init_e2e(3)
    integer i, j, ib


    ! init_e2e makes easy to add fixed distances between specific beads in future
    call random_number(urand,rand_stat)
    if (WLC_P__RING) then
        init_e2e = 0.0_dp
        ib = 1
        do i = 1,WLC_P__NP
            call make_rw_fix_end2end(R(:,IB:IB+WLC_P__NB-1), WLC_P__NB, init_e2e, wlc_p, rand_stat)
            IB = IB + WLC_P__NB
        enddo
    else
        ib = 1
        do i = 1, WLC_P__NP
            call make_rw_with_boundary(R(:,IB:IB+WLC_P__NB-1), WLC_P__NB, wlc_p, rand_stat)
            IB = IB + WLC_P__NB
        enddo

    end if
    IB = 1
    do I = 1,WLC_P__NP
        U(1,IB) = R(1,IB + 1) - R(1,IB)
        U(2,IB) = R(2,IB + 1) - R(2,IB)
        U(3,IB) = R(3,IB + 1) - R(3,IB)
        U(:,IB) = U(:,IB)/norm2(U(:,IB))
        IB = IB + 1
        do J = 2,WLC_P__NB-1
            U(1,IB) = R(1,IB + 1) - R(1,IB - 1)
            U(2,IB) = R(2,IB + 1) - R(2,IB - 1)
            U(3,IB) = R(3,IB + 1) - R(3,IB - 1)
            U(:,IB) = U(:,IB)/norm2(U(:,IB))
            IB = IB + 1
        enddo
        U(1,IB) = R(1,IB) - R(1,IB - 1)
        U(2,IB) = R(2,IB) - R(2,IB - 1)
        U(3,IB) = R(3,IB) - R(3,IB - 1)
        U(:,IB) = U(:,IB)/norm2(U(:,IB))
        IB = IB + 1
     enddo
end subroutine gaus_init

subroutine make_rw_fix_end2end(R, NB, e2e, wlc_p, rand_stat)
    ! for a GC, we should have
    ! SIGMA = sqrt(2.0_dp*WLC_P__LP*WLC_P__L/3.0_dp/WLC_P__NB)

    use params, only : dp, wlcsim_params
    use mersenne_twister

    implicit none

    type(wlcsim_params), intent(in) :: wlc_p
    type(random_stat) rand_stat  ! state of random number chain
    real(dp), intent(in) :: e2e(3)
    integer, intent(in) :: nb
    real(dp), intent(out) :: R(3,nb)
    integer :: j
    real(dp) :: actual_e2e(3)

    call make_rw_with_boundary(R, NB, wlc_p, rand_stat)
    actual_e2e = R(:,NB) - R(:,1)
    do J = 2,NB
        R(:,J) = R(:,J) - actual_e2e*(J-1)/(NB-1)
        R(:,J) = R(:,J) + e2e*(J-1)/(NB-1)
    enddo
end subroutine

subroutine make_rw_with_boundary(R, NB, wlc_p, rand_stat)
    ! for a GC, we should have
    ! SIGMA = sqrt(2.0_dp*WLC_P__LP*WLC_P__L/3.0_dp/WLC_P__NB)

    use params, only : dp, wlcsim_params
    use mersenne_twister

    implicit none

    type(wlcsim_params), intent(in) :: wlc_p
    type(random_stat) rand_stat  ! state of random number chain
    integer, intent(in) :: nb
    real(dp), intent(out) :: R(3,nb)
    integer :: ib, j
    real nrand(3)
    logical in_confinement, is_inside_boundary


    ! initialize as if it were a gaussian chain, first bead at zero
    !TODO add function to src/util/confinement to make this unif in confinement
    IB = 1
    R(1,IB) = 0.0_dp
    R(2,IB) = 0.0_dp
    R(3,IB) = 0.0_dp
    IB = IB + 1
    do J = 2,NB
        is_inside_boundary = .False.
        do while (.not. is_inside_boundary)
            call random_gauss(nrand, rand_stat)
            R(1,IB) = R(1,IB-1) + wlc_p%SIGMA*nrand(1)
            R(2,IB) = R(2,IB-1) + wlc_p%SIGMA*nrand(2)
            R(3,IB) = R(3,IB-1) + wlc_p%SIGMA*nrand(3)
            is_inside_boundary = in_confinement(R, NB, IB, IB)
        enddo
        IB = IB + 1
    enddo
end subroutine
