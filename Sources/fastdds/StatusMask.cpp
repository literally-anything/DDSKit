#include "StatusMask.hpp"

void _statusMaskAdd(_StatusMask &mask1, _StatusMask mask2) {
    mask1 << mask2;
}
void _statusMaskSubtract(_StatusMask &mask1, _StatusMask mask2) {
    mask1 >> mask2;
}
