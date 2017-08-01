!---------------------------------------------------------------*

!     subroutine MC_eelas
!
!     Calculate the change in the polymer elastic energy
!     due to the displacement from a MC move
!
subroutine MC_eelas(DEELAS,R,U,RP,UP,&
                    NT,NB,IB1,IB2,&
                    IT1,IT2,EB,EPAR,EPERP,GAM,ETA, &
                    RinG,TWIST,Lk,lt,L,MCTYPE,WR,WRP, &
                    SIMTYPE)

use params, only: dp, pi
implicit none
integer, intent(in) :: NT, SIMTYPE
real(dp), intent(in) :: R(3,NT)  ! Bead positions
real(dp), intent(in) :: U(3,NT)  ! Tangent vectors
real(dp), intent(in) :: RP(NT,3)  ! Bead positions
real(dp), intent(in) :: UP(NT,3)  ! Tangent vectors
integer, intent(in) :: NB                ! Number of beads in a polymer
integer, intent(in) :: IB1               ! Test bead position 1
integer, intent(in) :: IT1               ! Index of test bead 1
integer, intent(in) :: IB2               ! Test bead position 2
integer, intent(in) :: IT2               ! Index of test bead 2

real(dp) :: U0(NT,3)  ! dummy variable for calculating u in wlc case
real(dp) :: UP0(NT,3)  ! dummy variable for calculating u in wlc case
real(dp) :: UNORM,U1U2

real(dp), intent(out) :: DEELAS(4)   ! Change in ECOM

!     Polymer properties

real(dp), intent(in) :: EB
real(dp), intent(in) :: EPAR
real(dp), intent(in) :: EPERP
real(dp), intent(in) :: GAM
real(dp), intent(in) :: ETA
integer  Lk               ! Linking number
real(dp) L        ! Contour length
real(dp) lt       ! Twist persistence length
real(dp) Tw       ! Twist
real(dp) TWP      ! Twist of test structure
real(dp) WR       ! Writhe
real(dp), intent(out) :: WRP      ! Writhe of test structure
real(dp) DWR      ! Change in Writhe
real(dp) WRM,WRMP ! Component of writhe affected by move
logical RinG              ! Is polymer a ring?
logical TWIST             ! Include twist?
integer IT1M1
integer IT1P1
integer IT2M1
integer IT2P1
integer MCTYPE            ! MC move type

real(dp) DR(3),DRPAR,DRPERP(3)
real(dp) GI(3)

! Setup parameters

      DEELAS(1) = 0.0_dp ! bending energy
      DEELAS(2) = 0.0_dp ! parallel stretch energy
      DEELAS(3) = 0.0_dp ! perpendicular stretch energy
      DEELAS(4) = 0.0_dp ! twist energy

!     Calculate the change in the energy

      if ((IB1 /= 1).or.(RinG)) then
          ! so if RinG == 1, i.e.
          if (IB1 == 1) then
              ! then the bead to the left of IB1 is actually the end bead due to the ring inducing periodic boundaries on the array
              IT1M1 = NB
          else
              IT1M1 = IT1 - 1
          endif

         ! MC move only affects energy if it's interior to the polymer, since there are only crankshaft moves, and end
         ! crankshafts don't affect polymer
         if (SIMTYPE == 1.AND.(IB1 /= NB.OR.RinG)) then
             if (IB1 == NB) then
                 IT1P1 = 1
             else
                 IT1P1 = IT1 + 1
             endif
             print*, "You will need to update this section before use."
             print*, "Finish implementing IT1 and IT2"
             stop 1

            U0(IT1M1,1) = R(1,IT1)-R(1,IT1M1)
            U0(IT1M1,2) = R(2,IT1)-R(2,IT1M1)
            U0(IT1M1,3) = R(3,IT1)-R(3,IT1M1)
            UNORM = sqrt(U0(IT1M1,1)**2. + U0(IT1M1,2)**2. + U0(IT1M1,3)**2.)
            U0(IT1M1,1) = U0(IT1M1,1)/UNORM
            U0(IT1M1,2) = U0(IT1M1,2)/UNORM
            U0(IT1M1,3) = U0(IT1M1,3)/UNORM

            U0(IT1,1) = R(1,IT1 + 1)-R(1,IT1)
            U0(IT1,2) = R(2,IT1 + 1)-R(2,IT1)
            U0(IT1,3) = R(3,IT1 + 1)-R(3,IT1)
            UNORM = sqrt(U0(IT1,1)**2. + U0(IT1,2)**2. + U0(IT1,3)**2.)
            U0(IT1,1) = U0(IT1,1)/UNORM
            U0(IT1,2) = U0(IT1,2)/UNORM
            U0(IT1,3) = U0(IT1,3)/UNORM

            UP0(IT1,1) = RP(IT1 + 1,1)-RP(IT1,1)
            UP0(IT1,2) = RP(IT1 + 1,2)-RP(IT1,2)
            UP0(IT1,3) = RP(IT1 + 1,3)-RP(IT1,3)
            UNORM = sqrt(UP0(IT1,1)**2. + UP0(IT1,2)**2. + UP0(IT1,3)**2.)
            UP0(IT1,1) = UP0(IT1,1)/UNORM
            UP0(IT1,2) = UP0(IT1,2)/UNORM
            UP0(IT1,3) = UP0(IT1,3)/UNORM

            U1U2 = U0(IT1M1,1)*U0(IT1,1) + U0(IT1M1,2)*U0(IT1,2) + U0(IT1M1,3)*U0(IT1,3)
            ! only bending energy in WLC, others are init to zero, so sum in total energy calculation later will be no-op
            DEELAS(1) = DEELAS(1) + EB*U1U2
            U1U2 = U(1,IT1M1)*UP0(IT1,1) + U(2,IT1M1)*UP(IT1,2) + U(3,IT1M1)*UP(IT1,3)
            DEELAS(1) = DEELAS(1)-EB*U1U2

         elseif (SIMTYPE == 2) then

            DR(1) = R(1,IT1)-R(1,IT1M1)
            DR(2) = R(2,IT1)-R(2,IT1M1)
            DR(3) = R(3,IT1)-R(3,IT1M1)
            DRPAR = DR(1)*U(1,IT1M1) + DR(2)*U(2,IT1M1) + DR(3)*U(3,IT1M1)

            DRPERP(1) = DR(1)-DRPAR*U(1,IT1M1)
            DRPERP(2) = DR(2)-DRPAR*U(2,IT1M1)
            DRPERP(3) = DR(3)-DRPAR*U(3,IT1M1)
            !U1U2 = U(1,IT1M1)*U(1,IT1) + U(2,IT1M1)*U(2,IT1) + U(3,IT1M1)*U(3,IT1)

            GI(1) = (U(1,IT1)-U(1,IT1M1)-ETA*DRPERP(1))
            GI(2) = (U(2,IT1)-U(2,IT1M1)-ETA*DRPERP(2))
            GI(3) = (U(3,IT1)-U(3,IT1M1)-ETA*DRPERP(3))

            DEELAS(1) = DEELAS(1)-0.5_dp*EB*(GI(1)**2 + GI(2)**2 + GI(3)**2)
            DEELAS(2) = DEELAS(2)-0.5_dp*EPAR*(DRPAR-GAM)**2
            DEELAS(3) = DEELAS(3)-0.5_dp*EPERP*(DRPERP(1)**2 + DRPERP(2)**2. + DRPERP(3)**2)

            DR(1) = RP(IT1,1)-R(1,IT1M1)
            DR(2) = RP(IT1,2)-R(2,IT1M1)
            DR(3) = RP(IT1,3)-R(3,IT1M1)
            DRPAR = DR(1)*U(1,IT1M1) + DR(2)*U(2,IT1M1) + DR(3)*U(3,IT1M1)

            DRPERP(1) = DR(1)-DRPAR*U(1,IT1M1)
            DRPERP(2) = DR(2)-DRPAR*U(2,IT1M1)
            DRPERP(3) = DR(3)-DRPAR*U(3,IT1M1)
            !U1U2 = U(1,IT1M1)*UP(IT1,1) + U(2,IT1M1)*UP(IT1,2) + U(3,IT1M1)*UP(IT1,3)

            GI(1) = (UP(IT1,1)-U(1,IT1M1)-ETA*DRPERP(1))
            GI(2) = (UP(IT1,2)-U(2,IT1M1)-ETA*DRPERP(2))
            GI(3) = (UP(IT1,3)-U(3,IT1M1)-ETA*DRPERP(3))

            ! in ssWLC, we have, bending, parallel extension, and perpendicular extension energy, which we must sum later to get
            ! total energy
            DEELAS(1) = DEELAS(1) + 0.5_dp*EB*(GI(1)**2 + GI(2)**2 + GI(3)**2)
            DEELAS(2) = DEELAS(2) + 0.5_dp*EPAR*(DRPAR-GAM)**2
            DEELAS(3) = DEELaS(3) + 0.5_dp*EPERP*(DRPERP(1)**2 + DRPERP(2)**2 + DRPERP(3)**2)

         elseif (SIMTYPE == 3) then

            DR(1) = R(1,IT1)-R(1,IT1M1)
            DR(2) = R(2,IT1)-R(2,IT1M1)
            DR(3) = R(3,IT1)-R(3,IT1M1)
            ! in gaussian chain, there's only parallel stretching energy. DEELAS init'd to zeros, so sum(DEELAS) == DEELAS(2) later
            DEELAS(2) = DEELAS(2)-0.5*EPAR*(DR(1)**2. + DR(2)**2. + DR(3)**2.)
            DR(1) = RP(IT1,1)-R(1,IT1M1)
            DR(2) = RP(IT1,2)-R(2,IT1M1)
            DR(3) = RP(IT1,3)-R(3,IT1M1)
            DEELAS(2) = DEELAS(2) + 0.5*EPAR*(DR(1)**2. + DR(2)**2. + DR(3)**2.)

         endif
      endif

      if ((IB2 /= NB).or.(RinG)) then
         if (IB2 == NB) then
             IT2P1 = 1
         else
             IT2P1 = IT2 + 1
         endif

         ! if we're talking about a WLC, if we crankshaft a single bead, that's a no-op, since the u's are directly
         ! determined by the r's. Thus we're not worried about double counting the energy change here since the energy change
         ! should be zero by definition if IB1 = =IB2.
         if (SIMTYPE == 1.AND.((IB2 /= 1).OR.(RinG))) then
            if (IB2 == 1) then
                IT2M1 = NB
            else
                IT2M1 = IT2 - 1
            endif
            Print*, "This section is out of date"
            print*, "The variable IT2M1 is never used!"
            stop
            U0(IT2-1,1) = R(1,IT2)-R(1,IT2-1)
            U0(IT2-1,2) = R(2,IT2)-R(2,IT2-1)
            U0(IT2-1,3) = R(3,IT2)-R(3,IT2-1)
            UNORM = sqrt(U(1,IT2-1)**2. + U(2,IT2-1)**2. + U(3,IT2-1)**2.)
            U0(IT2-1,1) = U0(IT2-1,1)/UNORM
            U0(IT2-1,2) = U0(IT2-1,2)/UNORM
            U0(IT2-1,3) = U0(IT2-1,3)/UNORM

            U0(IT2,1) = R(1,IT2 + 1)-R(1,IT2)
            U0(IT2,2) = R(2,IT2 + 1)-R(2,IT2)
            U0(IT2,3) = R(3,IT2 + 1)-R(3,IT2)
            UNORM = sqrt(U0(IT2,1)**2. + U0(IT2,2)**2. + U0(IT2,3)**2.)
            U0(IT2,1) = U0(IT2,1)/UNORM
            U0(IT2,2) = U0(IT2,2)/UNORM
            U0(IT2,3) = U0(IT2,3)/UNORM

            UP0(IT2-1,1) = RP(IT2,1)-RP(IT2-1,1)
            UP0(IT2-1,2) = RP(IT2,2)-RP(IT2-1,2)
            UP0(IT2-1,3) = RP(IT2,3)-RP(IT2-1,3)
            UNORM = sqrt(UP0(IT2-1,1)**2. + UP0(IT2-1,2)**2. + UP0(IT2-1,3)**2.)
            UP0(IT2-1,1) = UP0(IT2-1,1)/UNORM
            UP0(IT2-1,2) = UP0(IT2-1,2)/UNORM
            UP0(IT2-1,3) = UP0(IT2-1,3)/UNORM

            U1U2 = U0(IT2-1,1)*U0(IT2,1) + U0(IT2-1,2)*U0(IT2,2) + U0(IT2-1,3)*U0(IT2,3)
            DEELAS(1) = DEELAS(1) + EB*U1U2
            U1U2 = UP0(IT2-1,1)*U0(IT2,1) + UP0(IT2-1,2)*U0(IT2,2) + UP0(IT2-1,3)*U0(IT2,3)
            DEELAS(1) = DEELAS(1)-EB*U1U2

         elseif (SIMTYPE == 2) then

            DR(1) = R(1,IT2P1)-R(1,IT2)
            DR(2) = R(2,IT2P1)-R(2,IT2)
            DR(3) = R(3,IT2P1)-R(3,IT2)
            DRPAR = DR(1)*U(1,IT2) + DR(2)*U(2,IT2) + DR(3)*U(3,IT2)

            DRPERP(1) = DR(1)-DRPAR*U(1,IT2)
            DRPERP(2) = DR(2)-DRPAR*U(2,IT2)
            DRPERP(3) = DR(3)-DRPAR*U(3,IT2)
            !U1U2 = U(1,IT2)*U(1,IT2 + 1) + U(2,IT2)*U(2,IT2 + 1) + U(3,IT2)*U(3,IT2 + 1)

            GI(1) = (U(1,IT2P1)-U(1,IT2)-ETA*DRPERP(1))
            GI(2) = (U(2,IT2P1)-U(2,IT2)-ETA*DRPERP(2))
            GI(3) = (U(3,IT2P1)-U(3,IT2)-ETA*DRPERP(3))

            DEELAS(1) = DEELAS(1)-0.5_dp*EB*(GI(1)**2. + GI(2)**2. + GI(3)**2.)
            DEELAS(2) = DEELAS(2)-0.5_dp*EPAR*(DRPAR-GAM)**2.
            DEELAS(3) = DEELAS(3)-0.5_dp*EPERP*(DRPERP(1)**2. + DRPERP(2)**2. + DRPERP(3)**2.)

            DR(1) = R(1,IT2P1)-RP(IT2,1)
            DR(2) = R(2,IT2P1)-RP(IT2,2)
            DR(3) = R(3,IT2P1)-RP(IT2,3)
            DRPAR = DR(1)*UP(IT2,1) + DR(2)*UP(IT2,2) + DR(3)*UP(IT2,3)

            DRPERP(1) = DR(1)-DRPAR*UP(IT2,1)
            DRPERP(2) = DR(2)-DRPAR*UP(IT2,2)
            DRPERP(3) = DR(3)-DRPAR*UP(IT2,3)
            !U1U2 = UP(IT2,1)*U(1,IT2 + 1) + UP(IT2,2)*U(2,IT2 + 1) + UP(IT2,3)*U(3,IT2 + 1)

            GI(1) = (U(1,IT2P1)-UP(IT2,1)-ETA*DRPERP(1))
            GI(2) = (U(2,IT2P1)-UP(IT2,2)-ETA*DRPERP(2))
            GI(3) = (U(3,IT2P1)-UP(IT2,3)-ETA*DRPERP(3))

            DEELAS(1) = DEELAS(1) + 0.5_dp*EB*(GI(1)**2. + GI(2)**2 + GI(3)**2)
            DEELAS(2) = DEELAS(2) + 0.5_dp*EPAR*(DRPAR-GAM)**2.
            DEELAS(3) = DEELAS(3) + 0.5_dp*EPERP*(DRPERP(1)**2. + DRPERP(2)**2. + DRPERP(3)**2.)

         elseif (SIMTYPE == 3) then

            DR(1) = R(1,IT2P1)-R(1,IT2)
            DR(2) = R(2,IT2P1)-R(2,IT2)
            DR(3) = R(3,IT2P1)-R(3,IT2)
            DEELAS(2) = DEELAS(2)-0.5*EPAR*(DR(1)**2. + DR(2)**2. + DR(3)**2.)
            DR(1) = R(1,IT2P1)-RP(IT2,1)
            DR(2) = R(2,IT2P1)-RP(IT2,2)
            DR(3) = R(3,IT2P1)-RP(IT2,3)
            DEELAS(2) = DEELAS(2) + 0.5*EPAR*(DR(1)**2. + DR(2)**2. + DR(3)**2.)

         endif

      endif

      if (RinG.AND.TWIST) then
          if (MCTYPE == 1) then
              CALL WRITHECRANK(R,IT1,IT2,NB,WRM)
              CALL WRITHECRANK(RP,IT1,IT2,NB,WRMP)
              DWR = WRMP-WRM
          elseif (MCTYPE == 2) then
              CALL WRITHESLIDE(R,IT1,IT2,NB,WRM)
              CALL WRITHESLIDE(RP,IT1,IT2,NB,WRMP)
              DWR = WRMP-WRM
          else
              DWR = 0.
          ENDif
          WRP = WR + DWR
          TW = REAL(LK)-WR
          TWP = REAL(LK)-WRP
          DEELAS(4) = DEELAS(4) + (((2.*pi*TWP)**2.)*LT/(2.*L))-(((2.*pi*TW)**2.)*LT/(2.*L))
      ENDif

      RETURN
      END

!---------------------------------------------------------------*
