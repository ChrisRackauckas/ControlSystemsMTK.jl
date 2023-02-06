using ControlSystemsMTK, ModelingToolkit, RobustAndOptimalControl, MonteCarloMeasurements
using ModelingToolkit: getdefault
unsafe_comparisons(true)

# Create a model
@parameters t k=10 k3=2 c=1
@variables x(t)=0 [bounds = (-2, 2)]
@variables v(t)=0
@variables u(t)=0
@variables y(t)=0

D = Differential(t)

eqs = [D(x) ~ v
       D(v) ~ -k * x - k3 * x^3 - c * v + 10u
       y ~ x]


@named duffing = ODESystem(eqs, t)

bounds = getbounds(duffing, states(duffing))
sample_within_bounds((l, u)) = (u - l) * rand() + l
# Create a vector of operating points
N = 10
xs = range(getbounds(x)[1], getbounds(x)[2], length=N)
ops = Dict.(x .=> xs)


Ps, ssys = batch_ss(duffing, [u], [y], ops)
@test length(Ps) == N

@test Ps[1] == ss(linearize(duffing, [u], [y]; op=ops[1])[1]...)
@test Ps[end] == ss(linearize(duffing, [u], [y]; op=ops[end])[1]...)

##

using DataInterpolations
@named Cgs = GainScheduledStateSpace(Ps, xs, interpolator=LinearInterpolation)
@test Cgs isa ODESystem
# This is tested better in the docs

## C-code generation
# using SymbolicControlSystems
# code = SymbolicControlSystems.print_c_array(stdout, Ps, xs, "gain_scheduled_controller", struct_name="hej", struct_type="kaj")