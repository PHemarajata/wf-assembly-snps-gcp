# Google Batch Migration Summary

## 🎯 **Migration Complete: Life Sciences API → Google Batch**

The pipeline has been successfully updated to use Google Batch instead of the deprecated Google Cloud Life Sciences API, ensuring long-term compatibility and incorporating proven production configuration patterns.

## 📋 **What Changed**

### **1. New Google Batch Configuration**
- **Replaced**: `google-lifesciences` executor → `google-batch` executor
- **Added**: Modern Google Batch configuration based on your proven setup
- **Updated**: All API references from Life Sciences to Batch API

### **2. New Profile: `gcb` (Recommended)**
Based on your existing configuration:
```bash
gcb {
    process.executor = 'google-batch'
    workDir          = 'gs://your-bucket/nextflow_work'
    batch.volumes    = ['gs://your-bucket/': '/mnt/gcs']
    batch.logsPolicy = 'ENABLED'
    google {
        project  = 'your-project-id'
        region   = 'us-central1'
        options  = '--labels=workflow=bacterial-genomics,env=prod'
    }
}
```

### **3. Updated API Requirements**
- **Removed**: `lifesciences.googleapis.com`
- **Added**: `batch.googleapis.com`

## 🚀 **New Usage Patterns**

### **Recommended: Use `gcb` Profile**
```bash
nextflow run bacterial-genomics/wf-assembly-snps-gcp \
    -profile gcb \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --gcp_work_dir gs://your-bucket/nextflow_work \
    --batch_volumes '["gs://your-bucket/": "/mnt/gcs"]' \
    --recombination clonalframeml \
    --use_preemptible true
```

### **Alternative: Updated `gcp_minimal` Profile**
```bash
nextflow run bacterial-genomics/wf-assembly-snps-gcp \
    -profile gcp_minimal \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --gcp_work_dir gs://your-bucket/nextflow_work \
    --recombination clonalframeml \
    --use_preemptible true
```

## 🔧 **New Parameters Available**

### **Google Batch Specific**
- `--gcp_work_dir` - Work directory in GCS (e.g., `gs://your-bucket/nextflow_work`)
- `--batch_volumes` - Mount GCS buckets (e.g., `["gs://your-bucket/": "/mnt/gcs"]`)
- `--gcp_labels` - Resource labels for tracking
- `--boot_disk_size` - Boot disk size (default: `20 GB`)
- `--cpu_platform` - Specific CPU platform (optional)

### **Network & Security**
- `--gcp_network` - VPC network (default: `default`)
- `--gcp_subnetwork` - Subnetwork (optional)
- `--use_private_address` - Use private IP addresses
- `--gcp_service_account` - Custom service account

## 📁 **Files Updated**

### **Configuration Files**
- ✅ `conf/profiles/gcp_minimal.config` - Updated to use Google Batch
- ✅ `conf/profiles/gcb.config` - **NEW** - Based on your proven config
- ✅ `conf/gcp_params.config` - Added Google Batch parameters
- ✅ `nextflow.config` - Added `gcb` profile

### **Setup & Documentation**
- ✅ `bin/setup_gcp.sh` - Updated API requirements
- ✅ `README.md` - Updated examples to use `gcb` profile
- ✅ `GOOGLE_BATCH_UPDATE.md` - **NEW** - This migration summary

## 🔍 **Key Benefits of Google Batch**

1. **Modern API**: Active development and support
2. **Better Logging**: Enhanced logging with `logsPolicy = 'ENABLED'`
3. **Improved Reliability**: Better error handling and retry mechanisms
4. **Cost Optimization**: Spot instances (equivalent to preemptible)
5. **Enhanced Monitoring**: Better integration with Cloud Monitoring

## 🛠️ **Setup Instructions**

### **1. Enable Google Batch API**
```bash
gcloud services enable batch.googleapis.com
```

### **2. Update Your Configuration**
Based on your existing setup, use these parameters:
```bash
--gcp_project "erudite-pod-307018"
--gcp_region "us-central1"
--gcp_work_dir "gs://aphlhq-ngs-gh/nextflow_work"
--batch_volumes '["gs://aphlhq-ngs-gh/": "/mnt/gcs"]'
--gcp_labels "--labels=workflow=assembly,env=dev"
```

### **3. Test the Configuration**
```bash
nextflow run bacterial-genomics/wf-assembly-snps-gcp \
    -profile gcb \
    --help
```

## 🔄 **Migration from Your Current Setup**

If you're currently using the Life Sciences API, here's how to migrate:

### **Before (Life Sciences)**
```bash
nextflow run your-pipeline \
    -profile google \
    --input gs://bucket/input/ \
    --outdir gs://bucket/results/
```

### **After (Google Batch)**
```bash
nextflow run bacterial-genomics/wf-assembly-snps-gcp \
    -profile gcb \
    --input gs://bucket/input/ \
    --outdir gs://bucket/results/ \
    --gcp_work_dir gs://bucket/nextflow_work \
    --batch_volumes '["gs://bucket/": "/mnt/gcs"]'
```

## ⚠️ **Important Notes**

1. **API Migration**: Ensure `batch.googleapis.com` is enabled
2. **Work Directory**: Must specify `--gcp_work_dir` for staging
3. **Volumes**: Use `--batch_volumes` to mount GCS buckets
4. **Spot Instances**: Use `--use_preemptible true` for cost savings
5. **Backward Compatibility**: Old `gcp_minimal` profile still works but uses Google Batch

## 📞 **Next Steps**

1. **Test the new configuration** with a small dataset
2. **Update your existing scripts** to use the `gcb` profile
3. **Monitor performance** and costs with the new setup
4. **Disable Life Sciences API** once migration is complete

The pipeline is now future-proof with Google Batch! 🚀☁️