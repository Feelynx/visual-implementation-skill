package com.example.wallet.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// Matches the balance-card design 1:1 (see design/balance-card.svg).
@Composable
fun ExistingBalanceScreen(onAddMoney: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp)
            .background(
                brush = Brush.linearGradient(
                    listOf(Color(0xFF4F46E5), Color(0xFF7C3AED))
                ),
                shape = RoundedCornerShape(16.dp)
            )
    ) {
        Column(Modifier.padding(18.dp)) {
            Text(
                text = "PREMIUM",
                color = Color(0xFFFFD166),
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .background(Color(0x33FFFFFF), RoundedCornerShape(8.dp))
                    .padding(horizontal = 8.dp, vertical = 2.dp)
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "Available balance",
                color = Color(0xFFB0B0C0),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "$2,480.00",
                color = Color.White,
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(20.dp))
            Button(onClick = onAddMoney, shape = RoundedCornerShape(20.dp)) {
                Text("Add money", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}
