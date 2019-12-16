
;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Plot data on a cross section
;   This script will plot data at a set angle through a specified point
;   This script adds lon/lat info along X-axis

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

; The WRF ARW input file.  
; This needs to have a ".nc" appended, so just do it.

; a = addfile("../wrfout_d03_2012-08-01_12:00:00.nc","r")

  wrffiles = systemfunc("ls /home/michell/S5-ERA5/wrfout_d04_*");/home/michell/REAL-ERA5//wrfout_d04_*

  numFiles = dimsizes(wrffiles)

  do i = 0, numFiles -1
    wrffiles(i) = wrffiles(i)+".nc"
  end do
  inpFiles = addfiles(wrffiles,"r")

; Type of plot to generate

; type = "x11"
 type = "pdf"
; type = "eps"
; type = "ncgm"
;  type = "png"

  wks = gsn_open_wks(type,"vert_cross-S5_EN")

; Set some basic resources

  res = True
;  res@MainTitle =""
  res@Footer = False

  pltres = True
  
;options for Land Use

  ter_res = True
  opts_ter = ter_res
  opts_ter@gsnYRefLine = 0.0
  opts_ter@gsnAboveYRefLineColor = "black"
; opts_ter@gsnAboveYRefLineColor = "darkgreen"
  opts_ter@gsnDraw = False
  opts_ter@gsnFrame = False
;  opts_ter@lbOrientation = "vertical"

; gsn_define_colormap (wks,"gui_default")
; gsn_define_colormap (wks,"wgne15")
; gsn_define_colormap (wks,"WhViBlGrYeOrReWh")
; gsn_define_colormap (wks,"ViReOrYeGrAqBl")

  gsn_define_colormap (wks,"BlAqGrYeOrReVi200")

; gsn_reverse_colormap(wks)           ; Reverse the color map.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  FirstTime = True
  FirstTimeMap = True

; LOOP OVER FILES

  do ifile = 0, numFiles-1      

    a = inpFiles[ifile]

    times  = wrf_user_getvar(a,"times",-1) ; get times in the file
    ntimes = dimsizes(times)         ; number of times in the file

    mdims = getfilevardimsizes(a,"P") ; get some dimension sizes for the file
    nd = dimsizes(mdims)

    xlat = wrf_user_getvar(a, "XLAT",0)
    xlon = wrf_user_getvar(a, "XLONG",0)
    ter = wrf_user_getvar(a, "HGT",0);HGT
    

;    nheight = conform(geopt,ter_no,(/1,2/)) 

;printVarSummary(ter_no)   
;    ter = nheight-geopt
    
;printVarSummary(ter)  
;    ter_new = ter(ter(1),ter(2)) 
;printVarSummary(ter_new)
;---------------------------------------------------------------

   do it = 0,ntimes-1,1             ; TIME LOOP
;    do it = 1,1                      ; TIME LOOP

      print("Working on time: " + times(it) )
      res@TimeLabel = times(it)   ; Set Valid time to use on plots

      u    = wrf_user_getvar(a,"ua",it)      ; u in m/s
      v    = wrf_user_getvar(a,"va",it)      ; v in m/s
      w    = wrf_user_getvar(a,"wa",it)      ; w in m/s
      tc   = wrf_user_getvar(a,"ua",it)      ; T in C
      rh   = wrf_user_getvar(a,"wa",it)      ; relative humidity
      z    = wrf_user_getvar(a, "z",it)      ; grid point height
      w    = w*100
      tc   = tc;-273.15
    ;;;Richardson number
      tv    = wrf_user_getvar(a, "tv",it)
      ri   = rigrad_bruntv_atm(tv, u, v, z, 0, 1 )
     ; rh   =rh*100 
; change description 
    tc@description = "Zonal Wind"
    tc@units = "m s-1"
    rh@description = "Vertical Velocity"
; get height info for labels
    
      if ( FirstTime ) then                
        zmin = 0.
        zmax = 3. ; We are only interested in the first 6km
;        nz   = floattoint(zmax+1)
         nz = 15 ;number of vertical levels
      end if

      opts_ter@trYMaxF = zmax*1000
      
;---------------------------------------------------------------

    do ip =2,2   

;     we are doing 3 plots all with the pivot point (plane) in the center of the domain
;     at angles 0, 45 and 90
      opt= True
      loc  = wrf_user_ij_to_ll(a,(/77,77/),(/77,96/),opt)
      print(loc)

      plane = new(4,float)
      plane = (/  77,77,  77,96  /) ; start x;y & end x;y point
;      plane = (/ mdims(nd-1)/2.3, mdims(nd-2) /)    ; pivot point is
                                                     ; center of domain (x,y)
      opts = True

      if(ip .eq. 1) then
        angle = 90.
        X_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
        X_desc = "longitude"
      end if

      if(ip .eq. 2) then
        angle = 0.
        X_plane = wrf_user_intrp2d(xlat,plane,angle,opts)
        X_desc = "latitude"
      end if

      if(ip .eq. 3) then
        angle = 45.
        X_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
        X_desc = "longitude"
      end if
      ;if working with meridional transects, choose meridional wind V
      u_plane = wrf_user_intrp3d(v,z,"v",plane,angle,opts)
      w_plane = wrf_user_intrp3d(w,z,"v",plane,angle,opts)
      rh_plane = wrf_user_intrp3d(rh,z,"v",plane,angle,opts)
      tc_plane = wrf_user_intrp3d(tc,z,"v",plane,angle,opts)
;printVarSummary(z)
      ter_plane = wrf_user_intrp2d(ter,plane,angle,opts)


;     print("Max terrain height in plot " + max(ter_plane))

      rh_plane2 = rh_plane
      tc_plane2 = tc_plane
      cross_dims = dimsizes(rh_plane2)
      rank = dimsizes(cross_dims)

;     printVarSummary(rh_plane2)

      iz_do = 25
      do iz = 0,24
        iz_do = iz_do-1
        do ix = 0,cross_dims(rank-1)-1
          if ( ismissing(rh_plane2(iz_do,ix)) ) then
            rh_plane2(iz_do,ix) = rh_plane2(iz_do+1,ix)
          end if
          if ( ismissing(tc_plane2(iz_do,ix)) ) then
            tc_plane2(iz_do,ix) = tc_plane2(iz_do+1,ix)
          end if
        end do
      end do

;     Find the index where 6km is - only need to do this once

      if ( FirstTime ) then
        zz = wrf_user_intrp3d(z,z,"v",plane,angle,opts)
        b = ind(zz(:,0) .gt. zmax*1000. )
        zmax_pos = b(0) - 1
        if ( abs(zz(zmax_pos,0)-zmax*1000.) .lt. abs(zz(zmax_pos+1,0)-zmax*1000.) ) then
          zspan = b(0) - 1
        else
          zspan = b(0)
        end if
        delete(zz)
        delete(b)
        FirstTime = False
      end if

;     X-axis lables

      dimsX = dimsizes(X_plane)
      xmin  = X_plane(0)
      xmax  = X_plane(dimsX(0)-1)
      xspan = dimsX(0)-1
;      nx    = floattoint( (xmax-xmin)/2 + 1)
      nx = 10 ; number of points on the x-axis (longitude)

;---------------------------------------------------------------
        
; Options for XY Plots

      opts_xy                         = res
      opts_xy@cnMissingValPerimOn     = True
      opts_xy@cnMissingValFillColor   = 0
      opts_xy@cnMissingValFillPattern = 11
      

      opts_xy@PlotOrientation         = tc_plane@Orientation

; X-axis

      opts_xy@tiXAxisString           = X_desc
      opts_xy@tmXTOn                  = False
      opts_xy@tmXBMode                = "Explicit"
      opts_xy@tmXBValues              = fspan(0,xspan,nx)
      opts_xy@tmXBLabels              = sprintf("%.2f",fspan(xmin,xmax,nx))  ; Create labels
      opts_xy@tmXBLabelFontHeightF    = 0.015
      opts_xy@tmXBMajorLengthF        = 0.02
      opts_xy@tiXAxisFontHeightF      = 0.02
      opts_xy@tiMainOn                = True ; Shouldn't be needed 
      opts_xy@MainTitlePos            = "Center"
      opts_xy@MainTitle               = times(it)
      opts_xy@ValidTime               = False
      opts_xy@InitTime                = False
      opts_xy@InitTime                = False
      opts_xy@cnInfoLabelOn           = False 
      opts_xy@lbBottomMarginF         = 0.05
      opts_xy@lbTitlePosition         = "Bottom"
      opts_xy@tmXBMajorOutwardLengthF = 0.021 ; set tickmarks 
      
      



; Y-axis

      opts_xy@tiYAxisString           = "Height (km)"
     ; opts_xy@tmYRLabelDirection          = ""
      opts_xy@tmYLMajorOutwardLengthF = 0.021
      opts_xy@tmYROn                  = False
      opts_xy@tmYLMode                = "Explicit"
      opts_xy@tmYLValues              = fspan(0,zspan,nz)  
      opts_xy@tmYLLabels              = sprintf("%.1f",fspan(zmin,zmax,nz))  ; Create labels
      opts_xy@tmYLLabelFontHeightF    = 0.015
      opts_xy@tiYAxisFontHeightF      = 0.02
      opts_xy@tmYLMajorLengthF        = 0.02

; Plotting options for RH

      opts_rh = opts_xy
    ;  opts_rh@ContourParameters        = (/ 0, 1, 0.05 /) ;ri number
    ; opts_rh@cnFillPalette   = "BlAqGrYeOrRe"; ri number
      opts_rh@ContourParameters        = (/ -.5, .5, 0.1 /)
      opts_rh@cnFillPalette   = "MPL_viridis"
      opts_rh@pmLabelBarOrthogonalPosF = -0.1 
      opts_rh@cnFillOn                 = True

;     opts_rh@cnFillColors            = (/"White","White","White", \
;                                         "White","Yellow", \
;                                         "Green","Cyan1","RoyalBlue", \
;                                         "DeepSkyBlue","Blue","Blue4"/)
;     opts_rh@cnFillColors            = (/"White","White","White", \
;                                         "White","Chartreuse","Green", \
;                                         "Green3","Green4", \
;                                         "ForestGreen","PaleGreen4"/)
;     opts@gsnSpreadColorEnd          = -2

; Plotting options for Temperature

      opts_tc = opts_xy
      opts_tc@cnInfoLabelZone = 1
      opts_tc@cnInfoLabelSide = "Top"
      opts_tc@cnInfoLabelPerimOn = False
      opts_tc@cnFillPalette   = "BlueDarkOrange18"
      opts_tc@cnInfoLabelOrthogonalPosF = -0.00005
      opts_tc@ContourParameters  = (/ -5.,5,.5 /)
     ; opts_tc@ContourParameters  = (/ 21.,31,.5 /)
      opts_tc@cnFillOn = True
; Contour terrain cross section

      contour_ter = gsn_csm_xy(wks,X_plane,ter_plane,opts_ter)

; Get the contour info for the rh and temp

      contour_tc = wrf_contour(a,wks,tc_plane(0:zmax_pos,:),opts_tc)
      contour_rh = wrf_contour(a,wks,rh_plane(0:zmax_pos,:),opts_rh)
      contour_tc2 = wrf_contour(a,wks,tc_plane2(0:zmax_pos,:),opts_tc)
      contour_rh2 = wrf_contour(a,wks,rh_plane2(0:zmax_pos,:),opts_rh)

;------------------------------------------------
; curly vector plot
;------------------------------------------------

        vecres                           = True            ; vector only resources
        vecres@gsnDraw                   = False           ; don't draw
        vecres@gsnFrame                  = False           ; don't advance frame
        vecres@vcRefMagnitudeF           = 15               ; define vector ref mag
        vecres@vcRefLengthF              = 0.045;0.0153           ; define length of vec ref
        vecres@vcRefAnnoOrthogonalPosF   = -1.079           ; move ref vector
        vecres@vcRefAnnoOn               = True            ;use vector reference
        vecres@vcRefAnnoString2On        = False           ;takes off the annotation below vector
        vecres@vcRefAnnoArrowLineColor   = "Black"           ; change ref vector color
        vecres@vcRefAnnoArrowUseVecColor = False           ; don't use vec color for ref
        vecres@vcMinDistanceF            = 0.025            ; larger means sparser
;       vecres@vcLineArrowHeadMaxSizeF   = 0.0075          ; default: 0.05 (LineArrow)
        vecres@vcLineArrowHeadMaxSizeF   = 0.012           ; default: 0.05 (LineArrow)
                                                           ;         0.012 (CurlyVector)
        vecres@vcGlyphStyle              = "CurlyVector"   ; turn on curley vectors
        vecres@vcLineArrowColor          = "black"         ; change vector color
        vecres@vcLineArrowThicknessF     = 1.2             ; change vector thickness
        vecres@vcVectorDrawOrder         = "PostDraw"      ; draw vectors last
        vecres@FieldTitle                = "Vert. Circ."   ; overwrite field title
;       vecres@units                     = " "             ; turn off units
;       vecres@gsnLeftString             = "LeftString"    ; add the gsn titles
;       vecres@gsnCenterString           = "centerstring"
;       vecres@gsnRightString            = "RightString"
        vecres@gsnMaximize               = True           ; maximize plot in frame
        vecres@NoHeaderFooter            = True        ; no model info
        vecres@Footer                    = False           ; no footer

        vector = wrf_vector(a,wks,u_plane(0:zmax_pos,:),w_plane(0:zmax_pos,:),vecres)


;---------------------------------------------------------------

; MAKE PLOTS         

      if (FirstTimeMap) then

        lat_plane = wrf_user_intrp2d(xlat,plane,angle,opts)
        lon_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
        mpres = True
        pltres = True
        pltres@FramePlot = False
        optsM = res
        optsM@NoHeaderFooter = True
        optsM@cnFillOn = True
        optsM@lbTitleOn = True
        contour  = wrf_contour(a,wks,ter,optsM)
        plot = wrf_map_overlays(a,wks,(/contour/),pltres,mpres)
        lnres = True
        lnres@gsLineThicknessF = 3.0
        lnres@gsLineColor = "Black"

        do ii = 0,dimsX(0)-2
          gsn_polyline(wks,plot,(/lon_plane(ii),lon_plane(ii+1)/),(/lat_plane(ii),lat_plane(ii+1)/),lnres)
        end do

        frame(wks)

        delete(lon_plane)
        delete(lat_plane)
        pltres@FramePlot = True

     end if

; plot x-section


     plot = wrf_overlays(a,wks,(/contour_rh,vector/),pltres)
     plot = wrf_overlays(a,wks,(/contour_tc,vector/),pltres)
;    plot = wrf_overlays(a,wks,(/contour_rh/),pltres)
;    plot = wrf_overlays(a,wks,(/contour_tc/),pltres)
;    plot = wrf_overlays(a,wks,(/contour_rh,contour_ter/),pltres)
;    plot = wrf_overlays(a,wks,(/contour_tc,contour_ter/),pltres)
;    plot = wrf_overlays(a,wks,(/contour_rh,contour_tc,contour_ter/),pltres)
;    plot = wrf_overlays(a,wks,(/contour_rh2,contour_tc2,contour_ter/),pltres)

; Delete options and fields, so we don't have carry over

      delete(opts_xy)
      delete(opts_tc)
      delete(opts_rh)
      delete(u_plane)
      delete(w_plane)
      delete(tc_plane)
      delete(rh_plane)
      delete(tc_plane2)
      delete(rh_plane2)
      delete(X_plane)
      delete(ter_plane)

    end do  ; make next cross section

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    FirstTimeMap = False

    end do        ; END OF TIME LOOP
  end do          ; END OF FILES LOOP

end

