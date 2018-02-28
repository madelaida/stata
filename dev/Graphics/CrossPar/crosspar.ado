* Cross-partials

cap prog drop crosspar
prog def crosspar
syntax anything , [scatter]

	local graph_opts title(, justification(left) color(black) span pos(11)) graphregion(color(white)) ylab(,angle(0) nogrid) xtit(,placement(left) justification(left)) legend(region(lc(none) fc(none)))
	tempvar resid
	
	* Loop over variables
	
		local x = 0
		
		unab anything : `anything'
		foreach var in `anything' {
			local indepvars = subinstr(" `anything' "," `var' "," ",.)
			
			local y = 0
			foreach indepvar in `indepvars' {
				local oindepvars = subinstr(" `indepvars' "," `indepvar' "," ",.)
				
				local ++x
				local ++y
				
				* Regress and predict residuals
				
				di in red "`x': `var' – `oindepvars' – `indepvar'"
				
				qui reg `var' `oindepvars'
					cap drop `resid'
					qui predict `resid' , resid
						qui replace `resid' = `resid' + _b[_cons]
						foreach rhsvar in `oindepvars' {
							qui su `rhsvar'
							qui replace `resid' = `resid' + `r(mean)'*_b[`rhsvar'] // Shift to overall mean
							}
					
				* Graph scatter of residuals
					
					local ytit : var label `var'
					local xtit : var label `indepvar'
					local title ""
						if `y' == 1 local title "`ytit'"
					if "`scatter'" != "" local theScatter "(scatter `resid' `indepvar' , m(.) msize(tiny) jitter(5) mc(gray))"
					if "`scatter'" == "" local theScatter "(lfit `resid' `indepvar' , lc(gray) lp(dash) lw(medthick))"
					
					qui reg `resid' `indepvar' `oindepvars' 
					local b = round(_b[`indepvar'],0.01)
					mat a = r(table)
						local p = a[4,1]
						local p = round(`p',0.001)
					if "`scatter'" == "" local theLabel "{&beta} = `b' ; p = `p'"
					
					tw ///
						`theScatter' ///
						(lpoly `resid' `indepvar' , lw(thick) lc(maroon)) ///
						, title({bf:`title'}) ytit(" ") xtit("{bf:`xtit' {&rarr}}" "`theLabel'") legend(off) `graph_opts'  nodraw
					
						qui graph save __`x'.gph, replace
						
						local theGraphs "`theGraphs' __`x'.gph"
					
				}
						
			}
		
	* Diagonal gaps in combine
	
		local n : word count `anything'
		local check = `x' + `n'
			
		forvalues i = 1/`check' {
			forvalues row = 1/`n' {	
				if (`i' == (`n')*(`row'-1)+`row') local theGaps "`theGaps' `i'"	
				}	
			}
			
	* Combine graph
		
		graph combine `theGraphs' , graphregion(color(gs14)) holes(`theGaps') r(`n') colfirst
		
	* Clean up
	
		qui forvalues i = 1/`x' {
			!rm __`i'.gph
			}
					
end

* Have a lovely day!
