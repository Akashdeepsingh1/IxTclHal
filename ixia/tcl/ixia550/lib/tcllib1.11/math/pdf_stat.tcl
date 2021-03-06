# pdf_stat.tcl --
#
#    Collection of procedures for evaluating probability and
#    cumulative density functions
#    Part of "math::statistics"
#
#    january 2008: added procedures by Eric Kemp Benedict for
#                  Gamma, Poisson and t-distributed variables.
#                  Replacing some older versions.
#

# ::math::statistics --
#   Namespace holding the procedures and variables
#
namespace eval ::math::statistics {

    namespace export pdf-normal pdf-uniform \
	    pdf-exponential \
	    cdf-normal cdf-uniform \
	    cdf-exponential \
	    cdf-students-t \
	    random-normal random-uniform \
	    random-exponential \
	    histogram-uniform \
	    pdf-gamma pdf-poisson pdf-chisquare pdf-students-t pdf-beta \
	    cdf-gamma cdf-poisson cdf-chisquare cdf-beta \
	    random-gamma random-poisson random-chisquare random-students-t random-beta \
	    incompleteGamma incompleteBeta

    variable cdf_normal_prob     {}
    variable cdf_normal_x        {}
    variable cdf_toms322_cached  {}
    variable initialised_cdf     0
    variable twopi               [expr {2.0*acos(-1.0)}]
    variable pi                  [expr {acos(-1.0)}]
}


# pdf-normal --
#    Return the probabilities belonging to a normal distribution
#
# Arguments:
#    mean     Mean of the distribution
#    stdev    Standard deviation
#    x        Value for which the probability must be determined
#
# Result:
#    Probability of value x under the given distribution
#
proc ::math::statistics::pdf-normal { mean stdev x } {
    variable NEGSTDEV
    variable factorNormalPdf

    if { $stdev <= 0.0 } {
	return -code error -errorcode ARG -errorinfo $NEGSTDEV $NEGSTDEV
    }

    set xn   [expr {($x-$mean)/$stdev}]
    set prob [expr {exp(-$xn*$xn/2.0)/$stdev/$factorNormalPdf}]

    return $prob
}


# pdf-uniform --
#    Return the probabilities belonging to a uniform distribution
#    (parameters as minimum/maximum)
#
# Arguments:
#    pmin      Minimum of the distribution
#    pmax      Maximum of the distribution
#    x         Value for which the probability must be determined
#
# Result:
#    Probability of value x under the given distribution
#
proc ::math::statistics::pdf-uniform { pmin pmax x } {

    if { $pmin >= $pmax } {
	return -code error -errorcode ARG \
		-errorinfo "Wrong order or zero range" \
		"Wrong order or zero range"
    }

    set prob [expr {1.0/($pmax-$min)}]

    if { $x < $pmin || $x > $pmax } { return 0.0 }

    return $prob
}


# pdf-exponential --
#    Return the probabilities belonging to an exponential
#    distribution
#
# Arguments:
#    mean     Mean of the distribution
#    x        Value for which the probability must be determined
#
# Result:
#    Probability of value x under the given distribution
#
proc ::math::statistics::pdf-exponential { mean x } {
    variable NEGSTDEV
    variable OUTOFRANGE

    if { $stdev <= 0.0 } {
	return -code error -errorcode ARG -errorinfo $NEGSTDEV $NEGSTDEV
    }
    if { $mean <= 0.0 } {
	return -code error -errorcode ARG -errorinfo $OUTOFRANGE \
		"$OUTOFRANGE: mean must be positive"
    }

    if { $x < 0.0 } { return 0.0 }
    if { $x > 700.0*$mean } { return 0.0 }

    set prob [expr {exp(-$x/$mean)/$mean}]

    return $prob
}


# cdf-normal --
#    Return the cumulative probability belonging to a normal distribution
#
# Arguments:
#    mean     Mean of the distribution
#    stdev    Standard deviation
#    x        Value for which the probability must be determined
#
# Result:
#    Cumulative probability of value x under the given distribution
#
proc ::math::statistics::cdf-normal { mean stdev x } {
    variable NEGSTDEV

    if { $stdev <= 0.0 } {
	return -code error -errorcode ARG -errorinfo $NEGSTDEV $NEGSTDEV
    }

    set xn    [expr {($x-$mean)/$stdev}]
    set prob1 [Cdf-toms322 1 5000 [expr {$xn*$xn}]]
    if { $xn > 0.0 } {
	set prob [expr {0.5+0.5*$prob1}]
    } else {
	set prob [expr {0.5-0.5*$prob1}]
    }

    return $prob
}


# cdf-students-t --
#    Return the cumulative probability belonging to the
#    Student's t distribution
#
# Arguments:
#    degrees  Number of degrees of freedom
#    x        Value for which the probability must be determined
#
# Result:
#    Cumulative probability of value x under the given distribution
#
proc ::math::statistics::cdf-students-t { degrees x } {

    if { $degrees <= 0 } {
	return -code error -errorcode ARG -errorinfo \
		"Number of degrees of freedom must be positive" \
		"Number of degrees of freedom must be positive"
    }

    set prob1 [Cdf-toms322 1 $degrees [expr {$x*$x}]]
    set prob  [expr {0.5+0.5*$prob1}]

    return $prob
}


# cdf-uniform --
#    Return the cumulative probabilities belonging to a uniform
#    distribution (parameters as minimum/maximum)
#
# Arguments:
#    pmin      Minimum of the distribution
#    pmax      Maximum of the distribution
#    x         Value for which the probability must be determined
#
# Result:
#    Cumulative probability of value x under the given distribution
#
proc ::math::statistics::cdf-uniform { pmin pmax x } {

    if { $pmin >= $pmax } {
	return -code error -errorcode ARG \
		-errorinfo "Wrong order or zero range" \
	    }

    set prob [expr {($x-$pmin)/($pmax-$min)}]

    if { $x < $pmin } { return 0.0 }
    if { $x > $pmax } { return 1.0 }

    return $prob
}


# cdf-exponential --
#    Return the cumulative probabilities belonging to an exponential
#    distribution
#
# Arguments:
#    mean     Mean of the distribution
#    x        Value for which the probability must be determined
#
# Result:
#    Cumulative probability of value x under the given distribution
#
proc ::math::statistics::cdf-exponential { mean x } {
    variable NEGSTDEV
    variable OUTOFRANGE

    if { $mean <= 0.0 } {
	return -code error -errorcode ARG -errorinfo $OUTOFRANGE \
		"$OUTOFRANGE: mean must be positive"
    }

    if { $x <  0.0 } { return 0.0 }
    if { $x > 30.0*$mean } { return 1.0 }

    set prob [expr {1.0-exp(-$x/$mean)}]

    return $prob
}


# Inverse-cdf-uniform --
#    Return the argument belonging to the cumulative probability
#    for a uniform distribution (parameters as minimum/maximum)
#
# Arguments:
#    pmin      Minimum of the distribution
#    pmax      Maximum of the distribution
#    prob      Cumulative probability for which the "x" value must be
#              determined
#
# Result:
#    X value that gives the cumulative probability under the
#    given distribution
#
proc ::math::statistics::Inverse-cdf-uniform { pmin pmax prob } {

    if {0} {
	if { $pmin >= $pmax } {
	    return -code error -errorcode ARG \
		    -errorinfo "Wrong order or zero range" \
		    "Wrong order or zero range"
	}
    }

    set x [expr {$pmin+$prob*($pmax-$pmin)}]

    if { $x < $pmin } { return $pmin }
    if { $x > $pmax } { return $pmax }

    return $x
}


# Inverse-cdf-exponential --
#    Return the argument belonging to the cumulative probability
#    for an exponential distribution
#
# Arguments:
#    mean      Mean of the distribution
#    prob      Cumulative probability for which the "x" value must be
#              determined
#
# Result:
#    X value that gives the cumulative probability under the
#    given distribution
#
proc ::math::statistics::Inverse-cdf-exponential { mean prob } {

    if {0} {
	if { $mean <= 0.0 } {
	    return -code error -errorcode ARG \
		    -errorinfo "Mean must be positive" \
		    "Mean must be positive"
	}
    }

    set x [expr {-$mean*log(1.0-$prob)}]

    return $x
}


# Inverse-cdf-normal --
#    Return the argument belonging to the cumulative probability
#    for a normal distribution
#
# Arguments:
#    mean      Mean of the distribution
#    stdev     Standard deviation of the distribution
#    prob      Cumulative probability for which the "x" value must be
#              determined
#
# Result:
#    X value that gives the cumulative probability under the
#    given distribution
#
proc ::math::statistics::Inverse-cdf-normal { mean stdev prob } {
    variable cdf_normal_prob
    variable cdf_normal_x

    variable initialised_cdf
    if { $initialised_cdf == 0 } {
       Initialise-cdf-normal
    }

    # Look for the proper probability level first,
    # then interpolate
    #
    # Note: the numerical data are connected to the length of
    #       the lists - see Initialise-cdf-normal
    #
    set size 32
    set idx  64
    for { set i 0 } { $i <= 7 } { incr i } {
	set upper [lindex $cdf_normal_prob $idx]
	if { $prob > $upper } {
	    set idx  [expr {$idx+$size}]
	} else {
	    set idx  [expr {$idx-$size}]
	}
	set size [expr {$size/2}]
    }
    #
    # We have found a value that is close to the one we need,
    # now find the enclosing interval
    #
    if { $upper < $prob } {
	incr idx
    }
    set p1 [lindex $cdf_normal_prob [expr {$idx-1}]]
    set p2 [lindex $cdf_normal_prob $idx]
    set x1 [lindex $cdf_normal_x    [expr {$idx-1}]]
    set x2 [lindex $cdf_normal_x    $idx           ]

    set x  [expr {$x1+($x2-$x1)*($prob-$p1)/($p2-$p1)}]

    return [expr {$mean+$stdev*$x}]
}


# Initialise-cdf-normal --
#    Initialise the private data for the normal cdf
#
# Arguments:
#    None
# Result:
#    None
# Side effect:
#    Variable cdf_normal_prob and cdf_normal_x are filled
#    so that we can use these as a look-up table
#
proc ::math::statistics::Initialise-cdf-normal { } {
    variable cdf_normal_prob
    variable cdf_normal_x

    variable initialised_cdf
    set initialised_cdf 1

    set dx [expr {10.0/128.0}]

    set cdf_normal_prob 0.5
    set cdf_normal_x    0.0
    for { set i 1 } { $i <= 64 } { incr i } {
	set x    [expr {$i*$dx}]
	if { $x != 0.0 } {
	    set prob [Cdf-toms322 1 5000 [expr {$x*$x}]]
	} else {
	    set prob 0.0
	}

	set cdf_normal_x    [concat [expr {-$x}] $cdf_normal_x $x]
	set cdf_normal_prob \
		[concat [expr {0.5-0.5*$prob}] $cdf_normal_prob \
		[expr {0.5+0.5*$prob}]]
    }
}


# random-uniform --
#    Return a list of random numbers satisfying a uniform
#    distribution (parameters as minimum/maximum)
#
# Arguments:
#    pmin      Minimum of the distribution
#    pmax      Maximum of the distribution
#    number    Number of values to generate
#
# Result:
#    List of random numbers
#
proc ::math::statistics::random-uniform { pmin pmax number } {

    if { $pmin >= $pmax } {
	return -code error -errorcode ARG \
		-errorinfo "Wrong order or zero range" \
		"Wrong order or zero range"
    }

    set result {}
    for { set i 0 }  {$i < $number } { incr i } {
	lappend result [Inverse-cdf-uniform $pmin $pmax [expr {rand()}]]
    }

    return $result
}


# random-exponential --
#    Return a list of random numbers satisfying an exponential
#    distribution
#
# Arguments:
#    mean      Mean of the distribution
#    number    Number of values to generate
#
# Result:
#    List of random numbers
#
proc ::math::statistics::random-exponential { mean number } {

    if { $mean <= 0.0 } {
	return -code error -errorcode ARG \
		-errorinfo "Mean must be positive" \
		"Mean must be positive"
    }

    set result {}
    for { set i 0 }  {$i < $number } { incr i } {
	lappend result [Inverse-cdf-exponential $mean [expr {rand()}]]
    }

    return $result
}


# random-normal --
#    Return a list of random numbers satisfying a normal
#    distribution
#
# Arguments:
#    mean      Mean of the distribution
#    stdev     Standard deviation of the distribution
#    number    Number of values to generate
#
# Result:
#    List of random numbers
#
# Note:
#    This version uses the Box-Muller transformation,
#    a quick and robust method for generating normally-
#    distributed numbers.
#
proc ::math::statistics::random-normal { mean stdev number } {
    variable twopi

    if { $stdev <= 0.0 } {
	return -code error -errorcode ARG \
		-errorinfo "Standard deviation must be positive" \
		"Standard deviation must be positive"
    }

#    set result {}
#    for { set i 0 }  {$i < $number } { incr i } {
#        lappend result [Inverse-cdf-normal $mean $stdev [expr {rand()}]]
#    }

    set result {}

    for { set i 0 }  {$i < $number } { incr i 2 } {
        set angle [expr {$twopi * rand()}]
        set rad   [expr {sqrt(-2.0*log(rand()))}]
        set xrand [expr {$rad * cos($angle)}]
        set yrand [expr {$rad * sin($angle)}]
        lappend result [expr {$mean + $stdev * $xrand}]
        if { $i < $number-1 } {
            lappend result [expr {$mean + $stdev * $yrand}]
        }
    }

    return $result
}


# Cdf-toms322 --
#    Calculate the cumulative density function for several distributions
#    according to TOMS322
#
# Arguments:
#    m         First number of degrees of freedom
#    n         Second number of degrees of freedom
#    x         Value for which the cdf must be calculated
#
# Result:
#    Cumulatve density at x - details depend on distribution
#
# Notes:
#    F-ratios:
#        m - degrees of freedom for numerator
#        n - degrees of freedom for denominator
#        x - F-ratio
#    Student's t (two-tailed):
#        m - 1
#        n - degrees of freedom
#        x - square of t
#    Normal deviate (two-tailed):
#        m - 1
#        n - 5000
#        x - square of deviate
#    Chi-square:
#        m - degrees of freedom
#        n - 5000
#        x - chi-square/m
#    The original code can be found at <http://www.netlib.org>
#
proc ::math::statistics::Cdf-toms322 { m n x } {
    if { $x == 0.0 } {
        return 0.0
    }
    set m [expr {$m < 300?  int($m) : 300}]
    set n [expr {$n < 5000? int($n) : 5000}]
    if { $m < 1 || $n < 1 } {
	return -code error -errorcode ARG \
		-errorinfo "Arguments m anf n must be greater/equal 1"
    }

    set a [expr {2*($m/2)-$m+2}]
    set b [expr {2*($n/2)-$n+2}]
    set w [expr {$x*double($m)/double($n)}]
    set z [expr {1.0/(1.0+$w)}]

    if { $a == 1 } {
	if { $b == 1 } {
	    set p [expr {sqrt($w)}]
	    set y 0.3183098862
	    set d [expr {$y*$z/$p}]
	    set p [expr {2.0*$y*atan($p)}]
	} else {
	    set p [expr {sqrt($w*$z)}]
	    set d [expr {$p*$z/(2.0*$w)}]
	}
    } else {
	if { $b == 1 } {
	    set p [expr {sqrt($z)}]
	    set d [expr {$z*$p/2.0}]
	    set p [expr {1.0-$p}]
	} else {
	    set d [expr {$z*$z}]
	    set p [expr {$z*$w}]
	}
    }

    set y [expr {2.0*$w/$z}]

    if { $a == 1 } {
	for { set j [expr {$b+2}] } { $j <= $n } { incr j 2 } {
	    set d [expr {(1.0+double($a)/double($j-2)) * $d*$z}]
	    set p [expr {$p+$d*$y/double($j-1)}]
	}
    } else {
	set power [expr {($n-1)/2}]
	set zk    [expr {pow($z,$power)}]
	set d     [expr {($d*$zk*$n)/$b}]
	set p     [expr {$p*$zk + $w*$z * ($zk-1.0)/($z-1.0)}]
    }

    set y [expr {$w*$z}]
    set z [expr {2.0/$z}]
    set b [expr {$n-2}]

    for { set i [expr {$a+2}] } { $i <= $m } { incr i 2 } {
	set j [expr {$i+$b}]
	set d [expr {$y*$d*double($j)/double($i-2)}]
	set p [expr {$p-$z*$d/double($j)}]
    }
    set prob $p
    if  { $prob < 0.0 } { set prob 0.0 }
    if  { $prob > 1.0 } { set prob 1.0 }

    return $prob
}


# Inverse-cdf-toms322 --
#    Return the argument belonging to the cumulative probability
#    for an F, chi-square or t distribution
#
# Arguments:
#    m         First number of degrees of freedom
#    n         Second number of degrees of freedom
#    prob      Cumulative probability for which the "x" value must be
#              determined
#
# Result:
#    X value that gives the cumulative probability under the
#    given distribution
#
# Note:
#    See the procedure Cdf-toms322 for more details
#
proc ::math::statistics::Inverse-cdf-toms322 { m n prob } {
    variable cdf_toms322_cached
    variable OUTOFRANGE

    if { $prob <= 0 || $prob >= 1 } {
	return -code error -errorcode $OUTOFRANGE $OUTOFRANGE
    }

    # Is the combination in cache? Then we can simply rely
    # on that
    #
    foreach {m1 n1 prob1 x1} $cdf_toms322_cached {
	if { $m1 == $m && $n1 == $n && $prob1 == $prob } {
	    return $x1
	}
    }

    #
    # Otherwise first find a value of x for which Cdf(x) exceeds prob
    #
    set x1  1.0
    set dx1 1.0
    while { [Cdf-toms322 $m $n $x1] < $prob } {
	set x1  [expr {$x1+$dx1}]
	set dx1 [expr {2.0*$dx1}]
    }

    #
    # Now, look closer
    #
    while { $dx1 > 0.0001 } {
	set p1 [Cdf-toms322 $m $n $x1]
	if { $p1 > $prob } {
	    set x1  [expr {$x1-$dx1}]
	} else {
	    set x1  [expr {$x1+$dx1}]
	}
	set dx1 [expr {$dx1/2.0}]
    }

    #
    # Cache the result
    #
    set last end
    if { [llength $cdf_toms322_cached] > 27 } {
	set last 26
    }
    set cdf_toms322_cached \
	    [concat [list $m $n $prob $x1] [lrange $cdf_toms322_cached 0 $last]]

    return $x1
}


# HistogramMake --
#    Distribute the "observations" according to the cdf
#
# Arguments:
#    cdf-values   Values for the cdf (relative number of observations)
#    number       Total number of "observations" in the histogram
#
# Result:
#    List of numbers, distributed over the buckets
#
proc ::math::statistics::HistogramMake { cdf-values number } {

    set assigned  0
    set result    {}
    set residue   0.0
    foreach cdfv $cdf-values {
	set sum      [expr {$number*($cdfv + $residue)}]
	set bucket   [expr {int($sum)}]
	set residue  [expr {$sum-$bucket}]
	set assigned [expr {$assigned-$bucket}]
	lappend result $bucket
    }
    set remaining [expr {$number-$assigned}]
    if { $remaining > 0 } {
	lappend result $remaining
    } else {
	lappend result 0
    }

    return $result
}


# histogram-uniform --
#    Return the expected histogram for a uniform distribution
#
# Arguments:
#    min       Minimum the distribution
#    max       Maximum the distribution
#    limits    upper limits for the histogram buckets
#    number    Total number of "observations" in the histogram
#
# Result:
#    List of expected number of observations
#
proc ::math::statistics::histogram-uniform { min max limits number } {
    if { $min >= $max } {
	return -code error -errorcode ARG \
		-errorinfo "Wrong order or zero range" \
		"Wrong order or zero range"
    }

    set cdf_result {}
    foreach limit $limits {
	lappend cdf_result [cdf-uniform $min $max $limit]
    }

    return [HistogramMake $cdf_result $number]
}


# incompleteGamma --
#     Evaluate the incomplete Gamma function Gamma(p,x)
#
# Arguments:
#     x         X-value
#     p         Parameter
#
# Result:
#     Value of Gamma(p,x)
#
# Note:
#     Implementation by Eric K. Benedict (2007)
#     Adapted from Fortran code in the Royal Statistical Society's StatLib
#     library (http://lib.stat.cmu.edu/apstat/), algorithm AS 32 (with
#     some modifications from AS 239)
#
#     Calculate normalized incomplete gamma function
#
#                     1       / x               p-1
#       P(p,x) =  --------   |   dt exp(-t) * t
#                 Gamma(p)  / 0
#
#     Tested some values against R's pgamma function
#
proc ::math::statistics::incompleteGamma {x p {tol 1.0e-9}} {
    set overflow 1.0e37

    if {$x < 0} {
        return -code error -errorcode ARG -errorinfo "x must be positive"
    }
    if {$p <= 0} {
        return -code error -errorcode ARG -errorinfo "p must be greater than or equal to zero"
    }

    # If x is zero, incGamma is zero
    if {$x == 0.0} {
        return 0.0
    }

    # Use normal approx is p > 1000
    if {$p > 1000} {
        set pn1 [expr {3.0 * sqrt($p) * (pow(1.0 * $x/$p, 1.0/3.0) + 1.0/(9.0 * $p) - 1.0)}]
        # pnorm is not robust enough for this calculation (overflows); cdf-normal could also be used
        return [::math::statistics::pnorm_quicker $pn1]
    }

    # If x is extremely large compared to a (and now know p < 1000), then return 1.0
    if {$x > 1.e8} {
        return 1.0
    }

    set factor [expr {exp($p * log($x) -$x - [::math::ln_Gamma $p])}]

    # Use series expansion (first option) or continued fraction
    if {$x <= 1.0 || $x < $p} {
        set gin 1.0
        set term 1.0
        set rn $p
        while {1} {
            set rn [expr {$rn + 1.0}]
            set term [expr {1.0 * $term * $x/$rn}]
            set gin [expr {$gin + $term}]
            if {$term < $tol} {
                set gin [expr {1.0 * $gin * $factor/$p}]
                break
            }
        }
    } else {
        set a [expr {1.0 - $p}]
        set b [expr {$a + $x + 1.0}]
        set term 0.0
        set pn1 1.0
        set pn2 $x
        set pn3 [expr {$x + 1.0}]
        set pn4 [expr {$x * $b}]
        set gin [expr {1.0 * $pn3/$pn4}]
        while {1} {
            set a [expr {$a + 1.0}]
            set b [expr {$b + 2.0}]
            set term [expr {$term + 1.0}]
            set an [expr {$a * $term}]
            set pn5 [expr {$b * $pn3 - $an * $pn1}]
            set pn6 [expr {$b * $pn4 - $an * $pn2}]
            if {$pn6 != 0.0} {
                set rn [expr {1.0 * $pn5/$pn6}]
                set dif [expr {abs($gin - $rn)}]
                if {$dif <= $tol && $dif <= $tol * $rn} {
                    break
                }
                set gin $rn
            }
            set pn1 $pn3
            set pn2 $pn4
            set pn3 $pn5
            set pn4 $pn6
            # Too big? Rescale
            if {abs($pn5) >= $overflow} {
                set pn1 [expr {$pn1 / $overflow}]
                set pn2 [expr {$pn2 / $overflow}]
                set pn3 [expr {$pn3 / $overflow}]
                set pn4 [expr {$pn4 / $overflow}]
            }
        }
        set gin [expr {1.0 - $factor * $gin}]
    }

    return $gin

}


# pdf-gamma --
#    Return the probabilities belonging to a gamma distribution
#
# Arguments:
#    alpha     Shape parameter
#    beta      Rate parameter
#    x         Value of variate
#
# Result:
#    Probability density of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
#    This uses the following parameterization for the gamma:
#        GammaDist(x) = beta * (beta * x)^(alpha-1) e^(-beta * x) / GammaFunc(alpha)
#    Here, alpha is the shape parameter, and beta is the rate parameter
#    Alternatively, a "scale parameter" theta = 1/beta is sometimes used
#
proc ::math::statistics::pdf-gamma { alpha beta x } {

    if {$beta < 0} {
        return -code error -errorcode ARG -errorinfo "Rate parameter 'beta' must be positive"
    }
    if {$x < 0.0} {
        return 0.0
    }

    set prod [expr {1.0 * $x * $beta}]
    set Galpha [expr {exp([::math::ln_Gamma $alpha])}]

    expr {(1.0 * $beta/$Galpha) * pow($prod, ($alpha - 1.0)) * exp(-$prod)}
}


# pdf-poisson --
#    Return the probabilities belonging to a Poisson
#    distribution
#
# Arguments:
#    mu       Mean of the distribution
#    k        Number of occurrences
#
# Result:
#    Probability of k occurrences under the given distribution
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
proc ::math::statistics::pdf-poisson { mu k } {
    set intk [expr {int($k)}]
    expr {exp(-$mu + floor($k) * log($mu) - [::math::ln_Gamma [incr intk]])}
}


# pdf-chisquare --
#    Return the probabilities belonging to a chi square distribution
#
# Arguments:
#    df        Degree of freedom
#    x         Value of variate
#
# Result:
#    Probability density of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
proc ::math::statistics::pdf-chisquare { df x } {

    if {$df <= 0} {
        return -code error -errorcode ARG -errorinfo "Degrees of freedom must be positive"
    }

    return [pdf-gamma [expr {0.5*$df}] 0.5 $x]
}


# pdf-students-t --
#    Return the probabilities belonging to a Student's t distribution
#
# Arguments:
#    degrees   Degree of freedom
#    x         Value of variate
#
# Result:
#    Probability density of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
proc ::math::statistics::pdf-students-t { degrees x } {
    variable pi

    if {$degrees <= 0} {
        return -code error -errorcode ARG -errorinfo "Degrees of freedom must be positive"
    }

    set nplus1over2 [expr {0.5 * ($degrees + 1)}]
    set f1 [expr {exp([::math::ln_Gamma $nplus1over2] - \
        [::math::ln_Gamma [expr {$nplus1over2 - 0.5}]])}]
    set f2 [expr {1.0/sqrt($degrees * $pi)}]

    expr {$f1 * $f2 * pow(1.0 + $x * $x/double($degrees), -$nplus1over2)}

}


# pdf-beta --
#    Return the probabilities belonging to a Beta distribution
#
# Arguments:
#    a         First parameter of the Beta distribution
#    b         Second parameter of the Beta distribution
#    x         Value of variate
#
# Result:
#    Probability density of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2008
#
proc ::math::statistics::pdf-beta { a b x } {
    if {$x < 0.0 || $x > 1.0} {
        return -code error "Value out of range in Beta density: x = $x, not in \[0, 1\]"
    }
    if {$a <= 0.0} {
        return -code error "Value out of range in Beta density: a = $a, must be > 0"
    }
    if {$b <= 0.0} {
        return -code error "Value out of range in Beta density: b = $b, must be > 0"
    }
    #
    # Corner cases ... need to check these!
    #
    if {$x == 0.0} {
        return 0.0
    }
    if {$x == 1.0} {
        return 0.0
    }
    set aplusb [expr {$a + $b}]
    set term1 [expr {[::math::ln_Gamma $aplusb]- [::math::ln_Gamma $a] - [::math::ln_Gamma $b]}]
    set term2 [expr {($a - 1.0) * log($x) + ($b - 1.0) * log(1.0 - $x)}]

    expr {exp($term1 + $term2)}
}


# incompleteBeta --
#    Evaluate the incomplete Beta integral
#
# Arguments:
#    a         First parameter of the Beta integral
#    b         Second parameter of the Beta integral
#    x         Integration limit
#    tol       (Optional) error tolerance (defaults to 1.0e-9)
#
# Result:
#    Probability density of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2008
#
proc ::math::statistics::incompleteBeta {a b x {tol 1.0e-9}} {
    if {$x < 0.0 || $x > 1.0} {
        return -code error "Value out of range in incomplete Beta function: x = $x, not in \[0, 1\]"
    }
    if {$a <= 0.0} {
        return -code error "Value out of range in incomplete Beta function: a = $a, must be > 0"
    }
    if {$b <= 0.0} {
        return -code error "Value out of range in incomplete Beta function: b = $b, must be > 0"
    }

    if {$x < $tol} {
        return 0.0
    }
    if {$x > 1.0 - $tol} {
        return 1.0
    }

    # Rearrange if necessary to get continued fraction to behave
    if {$x < 0.5} {
        return [beta_cont_frac $a $b $x $tol]
    } else {
        set z [beta_cont_frac $b $a [expr {1.0 - $x}] $tol]
        return [expr {1.0 - $z}]
    }
}


# beta_cont_frac --
#    Evaluate the incomplete Beta integral via a continued fraction
#
# Arguments:
#    a         First parameter of the Beta integral
#    b         Second parameter of the Beta integral
#    x         Integration limit
#    tol       (Optional) error tolerance (defaults to 1.0e-9)
#
# Result:
#    Probability density of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2008
#
#    Continued fraction for Ix(a,b)
#    Abramowitz & Stegun 26.5.9
#
proc ::math::statistics::beta_cont_frac {a b x {tol 1.0e-9}} {
    set max_iter 512

    set aplusb [expr {$a + $b}]
    set amin1 [expr {$a - 1}]
    set lnGapb [::math::ln_Gamma $aplusb]
    set term1 [expr {$lnGapb- [::math::ln_Gamma $a] - [::math::ln_Gamma $b]}]
    set term2 [expr {$a * log($x) + ($b - 1.0) * log(1.0 - $x)}]
    set pref [expr {exp($term1 + $term2)/$a}]

    set z [expr {$x / (1.0 - $x)}]

    set v 1.0
    set h_1 1.0
    set h_2 0.0
    set k_1 1.0
    set k_2 1.0

    for {set m 1} {$m < $max_iter} {incr m} {
        set f1 [expr {$amin1 + 2 * $m}]
        set e2m [expr {-$z * double(($amin1 + $m) * ($b - $m))/ \
            double(($f1 - 1) * $f1)}]
        set e2mp1 [expr {$z * double($m * ($aplusb - 1 + $m)) / \
            double($f1 * ($f1 + 1))}]
        set h_2m [expr {$h_1 + $e2m * $h_2}]
        set k_2m [expr {$k_1 + $e2m * $k_2}]

        set h_2 $h_2m
        set k_2 $k_2m

        set h_1 [expr {$h_2m + $e2mp1 * $h_1}]
        set k_1 [expr {$k_2m + $e2mp1 * $k_1}]

        set vprime [expr {$h_1/$k_1}]

        if {abs($v - $vprime) < $tol} {
            break
        }

        set v $vprime

    }

    if {$m == $max_iter} {
        return -code error "beta_cont_frac: Exceeded maximum number of iterations"
    }

    set retval [expr {$pref * $v}]

    # Because of imprecision in underlying Tcl calculations, may fall out of bounds
    if {$retval < 0.0} {
        set retval 0.0
    } elseif {$retval > 1.0} {
        set retval 1.0
    }

    return $retval
}


# cdf-gamma --
#    Return the cumulative probabilities belonging to a gamma distribution
#
# Arguments:
#    alpha     Shape parameter
#    beta      Rate parameter
#    x         Value of variate
#
# Result:
#    Cumulative probability of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
proc ::math::statistics::cdf-gamma { alpha beta x } {
    if { $x <= 0 } {
        return 0.0
    }
    incompleteGamma [expr {$beta * $x}] $alpha
}


# cdf-poisson --
#    Return the cumulative probabilities belonging to a Poisson
#    distribution
#
# Arguments:
#    mu       Mean of the distribution
#    x        Number of occurrences
#
# Result:
#    Probability of k occurrences under the given distribution
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
proc ::math::statistics::cdf-poisson { mu x } {
    return [expr {1.0 - [incompleteGamma $mu [expr {floor($x) + 1}]]}]
}


# cdf-chisquare --
#    Return the cumulative probabilities belonging to a chi square distribution
#
# Arguments:
#    df        Degree of freedom
#    x         Value of variate
#
# Result:
#    Cumulative probability of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
proc ::math::statistics::cdf-chisquare { df x } {

    if {$df <= 0} {
        return -code error -errorcode ARG -errorinfo "Degrees of freedom must be positive"
    }

    return [cdf-gamma [expr {0.5*$df}] 0.5 $x]
}


# cdf-beta --
#    Return the cumulative probabilities belonging to a Beta distribution
#
# Arguments:
#    a         First parameter of the Beta distribution
#    b         Second parameter of the Beta distribution
#    x         Value of variate
#
# Result:
#    Cumulative probability of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2008
#
proc ::math::statistics::cdf-beta { a b x } {
        incompleteBeta $a $b $x
}


# random-gamma --
#    Generate a list of gamma-distributed deviates
#
# Arguments:
#    alpha     Shape parameter
#    beta      Rate parameter
#    x         Value of variate
#
# Result:
#    List of random values
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#    Generate a list of gamma-distributed random deviates
#    Use Cheng's envelope rejection method, as documented in:
#        Dagpunar, J.S. 2007
#           "Simulation and Monte Carlo: With Applications in Finance and MCMC"
#
proc ::math::statistics::random-gamma {alpha beta number} {
    if {$alpha <= 1} {
        set lambda $alpha
    } else {
        set lambda [expr {sqrt(2.0 * $alpha - 1.0)}]
    }
    set retval {}
    for {set i 0} {$i < $number} {incr i} {
        while {1} {
            # Two rands: one for deviate, one for acceptance/rejection
            set r1 [expr {rand()}]
            set r2 [expr {rand()}]
            # Calculate deviate from enveloping proposal distribution (a Lorenz distribution)
            set lnxovera [expr {(1.0/$lambda) * (log(1.0 - $r1) - log($r1))}]
            if {![catch {expr {$alpha * exp($lnxovera)}} x]} {
                # Apply acceptance criterion
                if {log(4.0*$r1*$r1*$r2) < ($alpha - $lambda) * $lnxovera + $alpha - $x} {
                    break
                }
            }
        }
        lappend retval [expr {1.0 * $x/$beta}]
    }

    return $retval
}


# random-poisson --
#    Generate a list of Poisson-distributed deviates
#
# Arguments:
#    mu        Mean value
#    number    Number of deviates to return
#
# Result:
#    List of random values
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
proc ::math::statistics::random-poisson {mu number} {
    if {$mu < 20} {
        return [Randp_invert $mu $number]
    } else {
        return [Randp_PTRS $mu $number]
    }
}


# random-chisquare --
#    Return a list of random numbers according to a chi square distribution
#
# Arguments:
#    df        Degree of freedom
#    number    Number of values to return
#
# Result:
#    List of random numbers
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
proc ::math::statistics::random-chisquare { df number } {

    if {$df <= 0} {
        return -code error -errorcode ARG -errorinfo "Degrees of freedom must be positive"
    }

    return [random-gamma [expr {0.5*$df}] 0.5 $number]
}


# random-students-t --
#    Return a list of random numbers according to a chi square distribution
#
# Arguments:
#    degrees   Degree of freedom
#    number    Number of values to return
#
# Result:
#    List of random numbers
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
#    Use method from Appendix 4.3 in Dagpunar, J.S.,
#    "Simulation and Monte Carlo: With Applications in Finance and MCMC"
#
proc ::math::statistics::random-students-t { degrees number } {
    variable pi

    if {$degrees < 1} {
        return -code error -errorcode ARG -errorinfo "Degrees of freedom must be at least 1"
    }

    set dd [expr {double($degrees)}]
    set k [expr {2.0/($dd - 1.0)}]

    for {set i 0} {$i < $number} {incr i} {
        set r1 [expr {rand()}]
        if {$degrees > 1} {
            set r2 [expr {rand()}]
            set c [expr {cos(2.0 * $pi * $r2)}]
            lappend retval [expr {sqrt($dd/ \
                (1.0/(1.0 - pow($r1, $k)) \
                - $c * $c)) * $c}]
        } else {
            lappend retval [expr {tan(0.5 * $pi * ($r1 + $r1 - 1))}]
        }
    }
    set retval
}


# random-beta --
#    Return a list of random numbers according to a Beta distribution
#
# Arguments:
#    a         First parameter of the Beta distribution
#    b         Second parameter of the Beta distribution
#    number    Number of values to return
#
# Result:
#    Cumulative probability of the given value of x to occur
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2008
#
#    Use trick from J.S. Dagpunar, "Simulation and
#        Monte Carlo: With Applications in Finance
#        and MCMC", Section 4.5
#
proc ::math::statistics::random-beta { a b number } {
    set retval {}
    foreach w [random-gamma $a 1.0 $number] y [random-gamma $b 1.0 $number] {
        lappend retval [expr {$w / ($w + $y)}]
    }
    return $retval
}


# Random_invert --
#    Generate a list of Poisson-distributed deviates - method 1
#
# Arguments:
#    mu        Mean value
#    number    Number of deviates to return
#
# Result:
#    List of random values
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#
#    Generate a poisson-distributed random deviate
#    Use algorithm in section 4.9 of Dagpunar, J.S,
#       "Simulation and Monte Carlo: With Applications
#       in Finance and MCMC", pub. 2007 by Wiley
#    This inverts the cdf using a "chop-down" search
#    to avoid storing an extra intermediate value.
#    It is only good for small mu.
#
proc ::math::statistics::Randp_invert {mu number} {
    set W0 [expr {exp(-$mu)}]

    set retval {}

    for {set i 0} {$i < $number} {incr i} {
        set W $W0
        set R [expr {rand()}]
        set X 0

        while {$R > $W} {
            set R [expr {$R - $W}]
            incr X
            set W [expr {$W * $mu/double($X)}]
        }

        lappend retval $X
    }

    return $retval
}


# Random_PTRS --
#    Generate a list of Poisson-distributed deviates - method 2
#
# Arguments:
#    mu        Mean value
#    number    Number of deviates to return
#
# Result:
#    List of random values
#
# Note:
#    Implemented by Eric Kemp-Benedict, 2007
#    Generate a poisson-distributed random deviate
#    Use the transformed rejection method with
#    squeeze of Hoermann:
#        Wolfgang Hoermann, "The Transformed Rejection Method
#        for Generating Poisson Random Variables,"
#        Preprint #2, Dept of Applied Statistics and
#        Data Processing, Wirtshcaftsuniversitaet Wien,
#        http://statistik.wu-wien.ac.at/
#    This method works for mu >= 10.
#
proc ::math::statistics::Randp_PTRS {mu number} {
    set smu [expr {sqrt($mu)}]
    set b [expr {0.931 + 2.53 * $smu}]
    set a [expr {-0.059 + 0.02483 * $b}]
    set vr [expr {0.9277 - 3.6224/($b - 2.0)}]
    set invalpha [expr {1.1239 + 1.1328/($b - 3.4)}]
    set lnmu [expr {log($mu)}]

    set retval {}
    for {set i 0} {$i < $number} {incr i} {
        while 1 {
            set U [expr {rand() - 0.5}]
            set V [expr {rand()}]

            set us [expr {0.5 - abs($U)}]
            set k [expr {int(floor((2.0 * $a/$us + $b) * $U + $mu + 0.43))}]

            if {$us >= 0.07 && $V <= $vr} {
                break
            }

            if {$k < 0} {
                continue
            }

            if {$us < 0.013 && $V > $us} {
                continue
            }

            set kp1 [expr {$k+1}]
            if {log($V * $invalpha / ($a/($us * $us) + $b)) <= -$mu + $k * $lnmu - [::math::ln_Gamma $kp1]} {
                break
            }
        }

        lappend retval $k
    }
    return $retval
}


#
# Simple numerical tests
#
if { [info exists ::argv0] && ([file tail [info script]] == [file tail $::argv0]) } {

    #
    # Apparent accuracy: at least one digit more than the ones in the
    # given numbers
    #
    puts "Normal distribution - two-tailed"
    foreach z    {4.417 3.891 3.291 2.576 2.241 1.960 1.645 1.150 0.674
    0.319 0.126 0.063 0.0125} \
	    pexp {1.e-5 1.e-4 1.e-3 1.e-2 0.025 0.050 0.100 0.250 0.500
    0.750 0.900 0.950 0.990 } {
	set prob [::math::statistics::Cdf-toms322 1 5000 [expr {$z*$z}]]
	puts "$z - $pexp - [expr {1.0-$prob}]"
    }

    puts "Normal distribution (inverted; one-tailed)"
    foreach p {0.001 0.01 0.1 0.25 0.5 0.75 0.9 0.99 0.999} {
	puts "$p - [::math::statistics::Inverse-cdf-normal 0.0 1.0 $p]"
    }
    puts "Normal random variables"
    set rndvars [::math::statistics::random-normal 1.0 2.0 20]
    puts $rndvars
    puts "Normal uniform variables"
    set rndvars [::math::statistics::random-uniform 1.0 2.0 20]
    puts $rndvars
    puts "Normal exponential variables"
    set rndvars [::math::statistics::random-exponential 2.0 20]
    puts $rndvars
}
