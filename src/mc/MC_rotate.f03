#include "../defines.inc"
!--------------------------------------------------------------*
!
!           Makes Monti Carlo Move
!
!    Quinn separated out this file on 8/9/17
!
!---------------------------------------------------------------

! variables that need to be allocated only on certain branches moved into MD to prevent segfaults
! please move other variables in as you see fit
subroutine MC_rotate(IB1,IB2,IT1,IT2,MCAMP,rand_stat)
! values from wlcsim_data
use params, only: wlc_V, wlc_R, wlc_U, wlc_VP, wlc_RP&
    , wlc_UP, wlc_pointsMoved, wlc_nPointsMoved, wlc_bendPoints, wlc_nBend

use mersenne_twister
use params, only: dp
use vector_utils, only: axisAngle, randomUnitVec, rotateU
use polydispersity, only: get_IB, rightmost_from

implicit none
integer, intent(out) :: IB1   ! Test bead position 1
integer, intent(out) :: IT1   ! Index of test bead 1
integer, intent(out) :: IB2   ! Test bead position 2
integer, intent(out) :: IT2   ! Index of test bead 2

integer I  ! Test indices
! Things for random number generator
type(random_stat), intent(inout) :: rand_stat  ! status of random number generator
! Variables for the crank-shaft move

real(dp) TA(3)    ! Axis of rotation
real(dp) ROT(3,4) ! Rotation matrix
real(dp) ALPHA    ! Angle of move
real(dp) urnd(1) ! single random number
real(dp), parameter, dimension(3) ::  P1 = [0.0_dp, 0.0_dp, 0.0_dp]

!     MC adaptation variables

real(dp), intent(in) :: MCAMP ! Amplitude of random change
integer irnd(1)

!TOdo saving RP is not actually needed, even in these cases, but Brad's code assumes that we have RP.
if (WLC_P__RING .OR. WLC_P__INTERP_BEAD_LENNARD_JONES) then
    wlc_RP = wlc_R
    wlc_UP = wlc_U
endif

!     Perform rotate move (MCTYPE 4)
!     a.k.a. rotate a single bead
call random_index(WLC_P__NT,irnd,rand_stat)
IT1=irnd(1)
IB1=get_IB(IT1)
IB2 = IB1
IT2 = IT1

!  Which elastic segments change
wlc_nBend = 0
if (IB1>1) then
    wlc_nBend = wlc_nBend + 1
    wlc_bendPoints(wlc_nBend)=IT1-1
    I=IT1-1
    wlc_RP(:,I)=wlc_R(:,I)
    wlc_UP(:,I)=wlc_U(:,I)
    if (WLC_P__LOCAL_TWIST) wlc_VP(:,I) = wlc_V(:,I)
endif
if (IT2<rightmost_from(IT2)) then
    wlc_nBend = wlc_nBend + 1
    wlc_bendPoints(wlc_nBend)=IT2
    I=IT2+1
    wlc_RP(:,I)=wlc_R(:,I)
    wlc_UP(:,I)=wlc_U(:,I)
    if (WLC_P__LOCAL_TWIST) wlc_VP(:,I) = wlc_V(:,I)
endif

call randomUnitVec(TA,rand_stat)
call random_number(urnd,rand_stat)
ALPHA = MCAMP*(urnd(1)-0.5_dp)
call axisAngle(ROT,alpha,TA,P1)

I = IT1
wlc_UP(:,I) = rotateU(ROT,wlc_U(:,I))
wlc_RP(:,I) = wlc_R(:,I)
if (WLC_P__LOCAL_TWIST) wlc_VP(:,I) = rotateU(ROT,wlc_V(:,I))
wlc_nPointsMoved=wlc_nPointsMoved+1
wlc_pointsMoved(wlc_nPointsMoved)=I
end subroutine
