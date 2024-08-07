#include "StatusMask.hpp"

_StatusMask _statusMaskAdd(_StatusMask &mask1, _StatusMask mask2) {
    return mask1 << mask2;
}
_StatusMask _statusMaskSubtract(_StatusMask &mask1, _StatusMask mask2) {
    return mask1 >> mask2;
}
